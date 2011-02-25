/*
 * This file is part of libgsm0710mux
 *
 * (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 */

//===========================================================================
using GLib;
using CONST;
using Gsm0710;

//===========================================================================
// The Channel class
//
internal class Channel
{
    public enum Status
    {
        Requested,  /* requested on 07.10 layer, but not acknowledged by modem */
        Acked,      /* acknowledged by modem, but not opened by any client */
        Open,       /* acknowledged and opened by a client */
        Denied,     /* denied by the modem. this status is persistent */
        Shutdown,   /* shutting down, will no longer be openable */
    }

    // FIXME: Do we really want to expose the whole multiplexer object to the channel? Consider only using the relevant delegates.
    Multiplexer _multiplexer;
    Status _status;
    FsoFramework.Transport transport;
    FsoFramework.Logger logger;

    string _name;
    int _number;
    int _serial_status;

    SourceFunc ackCallback;
    uint ackTimeoutWatch;

    public Channel( Multiplexer? multiplexer,
                    Gsm0710mux.ChannelInfo info,
                    SourceFunc? ackCallback = null,
                    uint ackTimeout = 0 )
    {
        logger = FsoFramework.Logger.createFromKeyFile( FsoFramework.theConfig, LIBGSM0710MUX_CONFIG_SECTION, LIBGSM0710MUX_LOGGING_DOMAIN );
        logger.setReprDelegate( repr );

        _multiplexer = multiplexer;
        _status = Status.Requested;
        _name = info.consumer;
        _number = info.number;

        info.tspec.create();
        transport = info.tspec.transport;
        transport.setPriorities( TRANSPORT_READ_PRIORITY, TRANSPORT_WRITE_PRIORITY );
        transport.setDelegates( onRead, onHup );
        info.tspec.transport = transport;
        assert( logger.debug( "Constructed" ) );

        if ( ackTimeout > 0 )
        {
            ackTimeoutWatch = Timeout.add_seconds( ackTimeout, ackCallback );
        }
        this.ackCallback = ackCallback;
    }

    ~Channel()
    {
        assert( logger.debug( "Destructed" ) );
    }

    public string repr()
    {
        return "<%d (%s) connected via %s>".printf( _number, _name, transport != null? transport.getName() : "(none)" );
    }

    public string acked()
    {
        if ( ackTimeoutWatch > 0 )
        {
            Source.remove( ackTimeoutWatch );
        }

        assert( logger.debug( "Acked" ) );

        if ( !transport.open() )
        {
            logger.error( "Could not open transport: %s".printf( Posix.strerror( Posix.errno ) ) );
            return "";
        }

        _status = Status.Acked;

        if ( ackCallback != null )
        {
            assert( logger.debug( "AckCallback is set, calling" ) );
            Idle.add( () => {
                ackCallback();
                return false;
            } );
        }
        else
        {
            assert( logger.debug( "AckCallback NOT set" ) );
        }

        return transport.getName();
    }

    public void close()
    {
        assert( logger.debug( "Closing" ) );
        var oldstatus = _status;
        _status = Status.Shutdown;

        if ( oldstatus != Status.Requested )
        {
            if ( _multiplexer != null )
            {
                _multiplexer.channel_closed( _number );
            }
        }
        if ( transport != null )
        {
            transport.close();
            transport = null;
        }
        if ( _multiplexer != null )
        {
            _multiplexer.remove_channel( _number );
        }
        // NOTE: NO CODE BELOW HERE, as channel has been destructed
    }

    public string name()
    {
        return _name;
    }

    public string path()
    {
        return transport.getName();
    }

    public bool isAcked()
    {
        return _status != Status.Requested;
    }

    public void setSerialStatus( int newstatus )
    {
        assert( logger.debug( "setSerialStatus()" ) );

        var oldstatus = _serial_status;
        _serial_status = newstatus;

        if ( Gsm0710mux.Manager.leave_fc_alone )
        {
            return;
        }

        // check whether the FC bit has been set
        if ( ( ( oldstatus & SerialStatus.FC ) == 0 ) &&
                 ( ( newstatus & SerialStatus.FC ) == SerialStatus.FC ) )
        {
            logger.warning( "FC has been set. Disabling read from PTY" );
            transport.freeze();
        }

        // check whether the FC bit has been cleared
        if ( ( ( oldstatus & SerialStatus.FC ) == SerialStatus.FC ) &&
             ( ( newstatus & SerialStatus.FC ) == 0 ) )
        {
            logger.warning( "FC has been cleared. Reenabling read from PTY" );
            transport.thaw();
        }
    }

    public void deliverData( void* data, int len )
    {
        transport.write( data, len );
        //FIXME: how to ensure round-robin?
        //PARTIAL ANSWER: NOT by calling main-iteration nor Idle.add
        // This buffer is shared across all channels and data will
        // be corrupted on reentrancy!!!
    }

    //
    // delegates from Pty object
    //
    public void onRead( FsoFramework.Transport transport )
    {
        assert( logger.debug( "onRead() from Transport; reading." ) );
        assert( _multiplexer != null );

        if ( ( _serial_status & SerialStatus.FC ) == SerialStatus.FC )
        {
            logger.warning( "FC active... reading anyways..." );
        }

        var buffer = new char[8192];
        int bytesread = transport.read( buffer, 8192 );
        assert( logger.debug( @"Read $bytesread bytes" ) );

        _multiplexer.submit_data( _number, buffer, (int)bytesread );
    }

    public void onHup( FsoFramework.Transport transport )
    {
        assert( logger.debug( "onHup() from Transport; closing." ) );
        close();
    }

}
