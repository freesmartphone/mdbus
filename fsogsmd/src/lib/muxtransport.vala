/**
 * Copyright (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 */

using GLib;

namespace FsoGsm
{
    public const int MUX_TRANSPORT_MAX_BUFFER = 1024;
}

//===========================================================================
public class FsoGsm.LibGsm0710muxTransport : FsoFramework.BaseTransport
//===========================================================================
{
    static Gsm0710mux.Manager manager;
    private Gsm0710mux.ChannelInfo channelinfo;
    private FsoFramework.DelegateTransport tdelegate;

    private char[] buffer;
    private int length;

    static construct
    {
        manager = new Gsm0710mux.Manager();
    }

    public LibGsm0710muxTransport( int channel = 0 )
    {
        base( "LibGsm0710muxTransport" );

        buffer = new char[1024];
        length = 0;

        var version = manager.getVersion();
        var hasAutoSession = manager.hasAutoSession();
        assert( hasAutoSession ); // we do not support non-autosession yet

        tdelegate = new FsoFramework.DelegateTransport(
                                                      delegateWrite,
                                                      delegateRead,
                                                      delegateHup,
                                                      delegateOpen,
                                                      delegateClose,
                                                      delegateFreeze,
                                                      delegateThaw );

        channelinfo.tspec = FsoFramework.TransportSpec( "foo", "bar" );
        channelinfo.tspec.transport = tdelegate;
        channelinfo.number = channel;
        channelinfo.consumer = @"fsogsmd:$channel";

        assert( logger.debug( @"Created. Using libgsm0710mux version $version; autosession is $hasAutoSession" ) );
    }

    public override string repr()
    {
        return @"<0710:$(channelinfo.number)>";
    }

    public override bool open()
    {
        try
        {
            manager.allocChannel( ref channelinfo );
        }
        catch ( Gsm0710mux.MuxerError e )
        {
            logger.error( @"Can't open allocate channel #$(channelinfo.number) from MUX: $(e.message)" );
            return false;
        }
        return true;
    }

    public override int read( void* data, int length )
    {
        assert( this.length > 0 );
        assert( this.length < length );
        GLib.Memory.copy( data, this.buffer, this.length );
#if DEBUG
        message( @"READ %d from MUX #$(channelinfo.number): %s", length, ((string)data).escape( "" ) );
#endif
        var l = this.length;
        this.length = 0;
        return l;
    }

    public override int write( void* data, int length )
    {
        assert( this.length == 0 ); // NOT REENTRANT!
        assert( length < MUX_TRANSPORT_MAX_BUFFER );
#if DEBUG
        message( @"WRITE %d to MUX #$(channelinfo.number): %s", length, ((string)data).escape( "" ) );
#endif
        this.length = length;
        GLib.Memory.copy( this.buffer, data, length );
        tdelegate.readfunc( tdelegate );
        assert( this.length == 0 ); // everything has been consumed
        return length;
    }

    public override int freeze()
    {
        return -1; // we're not really freezing here
    }

    public override void thaw()
    {
    }

    public override void close()
    {
        manager.releaseChannel( channelinfo.consumer );
    }
    //
    // delegate transport interface
    //
    public bool delegateOpen( FsoFramework.Transport t )
    {
        message( "FROM MODEM OPEN ACK" );
        return true;
    }

    public void delegateClose( FsoFramework.Transport t )
    {
        message( "FROM MODEM CLOSE REQ" );
    }

    public int delegateWrite( void* data, int length, FsoFramework.Transport t )
    {
        if ( pppOut == null )
        {
            assert( this.length == 0 );
#if DEBUG
            message( @"FROM MODEM #$(channelinfo.number) WRITE $length" );
#endif
            assert( length < MUX_TRANSPORT_MAX_BUFFER );
            GLib.Memory.copy( this.buffer, data, length ); // prepare data
            this.length = length;
            this.readfunc( this ); // signalize data being available
            assert( this.length == 0 ); // all has been consumed
            return length;
        }
        else
        {
#if DEBUG
            message( @"FROM MODEM #$(channelinfo.number) FOR PPP WRITE $length" );
#endif
            var bwritten = Posix.write( pppInFd, data, length );
            assert( bwritten == length );
            return length;
        }
    }

    public int delegateRead( void* data, int length, FsoFramework.Transport t )
    {
        assert( this.length > 0 );
#if DEBUG
        message( @"FROM MODEM #$(channelinfo.number) READ $(this.length)" );
#endif
        assert( length > this.length );
        GLib.Memory.copy( data, this.buffer, this.length );
        var l = this.length;
        this.length = 0;
        return l;
    }

    public void delegateHup( FsoFramework.Transport t )
    {
        message( "FROM MODEM HUP" );
    }

    public int delegateFreeze( FsoFramework.Transport t )
    {
        message( "FROM MODEM FREEZE REQ" );
        return -1;
    }

    public void delegateThaw( FsoFramework.Transport t )
    {
        message( "FROM MODEM THAW REQ" );
    }

    //
    // PPP forwarding
    //

    private int pppInFd;
    private FsoFramework.Async.ReactorChannel pppOut;

    public bool isForwardingToPPP()
    {
        return ( pppOut != null );
    }

    public void startForwardingToPPP( int infd, int outfd )
    {
        message( @"START FORWARDING TO PPP VIA $infd <--> $outfd" );
        if ( pppOut != null )
        {
            return;
        }
        pppInFd = infd;
        pppOut = new FsoFramework.Async.ReactorChannel( outfd, onDataFromPPP );
    }

    public void stopForwardingToPPP()
    {
        message( @"STOP FORWARDING TO PPP" );
        if ( pppOut == null )
        {
            return;
        }
        pppOut = null;
    }

    public void onDataFromPPP( void* data, ssize_t length )
    {
        if ( data == null && length == 0 )
        {
            message( "EOF FROM PPP" );
            return;
        }
        message( "ON DATA FROM PPP" );
        var bwritten = write( data, (int)length );
        assert( bwritten == length );
    }
}
