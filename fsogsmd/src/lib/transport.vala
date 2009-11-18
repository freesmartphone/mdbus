/**
 * Copyright (C) 2009 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

//===========================================================================
public class FsoGsm.LibGsm0710muxTransport : FsoFramework.BaseTransport
//===========================================================================
{
    static Gsm0710mux.Manager manager;
    private Gsm0710mux.ChannelInfo channelinfo;

    static construct
    {
        manager = new Gsm0710mux.Manager();
    }

    public LibGsm0710muxTransport( int channel = 0 )
    {
        var version = manager.getVersion();
        var hasAutoSession = manager.hasAutoSession();
        assert( hasAutoSession ); // we do not support non-autosession yet

        channelinfo.tspec = FsoFramework.TransportSpec( "foo", "bar" );
        channelinfo.tspec.transport = new FsoFramework.DelegateTransport( delegateWrite,
                                                                          delegateRead,
                                                                          delegateHup,
                                                                          delegateOpen,
                                                                          delegateClose,
                                                                          delegateFreeze,
                                                                          delegateThaw );
        channelinfo.number = channel;
        channelinfo.consumer = "fsogsmd";

        debug( "FsoFramework.TransportLibGsm0710mux created, using libgsm0710mux version %s; autosession is %s".printf( version, hasAutoSession.to_string() ) );
    }

    public override bool open()
    {
        try
        {
            manager.allocChannel( ref channelinfo );
        }
        catch ( FsoFramework.TransportError e )
        {
            debug( "error: %s", e.message );
            return false;
        }

        return true;
    }

    public override int read( void* data, int length )
    {
        message( @"READ $length" );
        return 0;
    }

    public override int write( void* data, int length )
    {
        message( @"WRITE $length" );
        return 0;
    }

    public override void freeze()
    {
    }

    public override void thaw()
    {
    }

    public override string repr()
    {
        return "<LibGsm0710muxFsoFramework.Transport>";
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
        message( "FROM MODEM WRITE %d bytes", length );
        return 0;
    }

    public int delegateRead( void* data, int length, FsoFramework.Transport t )
    {
        message( "FROM MODEM READ %d bytes", length );
        return 0;
    }

    public void delegateHup( FsoFramework.Transport t )
    {
        message( "FROM MODEM HUP" );
    }

    public void delegateFreeze( FsoFramework.Transport t )
    {
        message( "FROM MODEM FREEZE REQ" );
    }

    public void delegateThaw( FsoFramework.Transport t )
    {
        message( "FROM MODEM THAW REQ" );
    }
}
