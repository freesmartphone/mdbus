/*
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

public class FsoGps.Channel : FsoFramework.AbstractCommandQueue, FsoFramework.IParserDelegate
{
    public const int COMMAND_QUEUE_BUFFER_SIZE = 4096;

    protected char* buffer;
    protected FsoFramework.Parser parser;

    protected string name;

    public Channel( string name, FsoFramework.Transport transport, FsoFramework.Parser parser )
    {
        base( transport );
        buffer = new char[COMMAND_QUEUE_BUFFER_SIZE];
        this.name = name;
        this.parser = parser;
        parser.setDelegate( this );
        theReceiver.registerChannel( name, this );
        theReceiver.signalStatusChanged.connect( onModemStatusChanged );
    }

    public override void onTransportDataAvailable( FsoFramework.Transport t )
    {
        var bytesread = transport.read( buffer, COMMAND_QUEUE_BUFFER_SIZE );

        if ( bytesread == 0 )
        {
            onTransportHangup( t );
            return;
        }

        buffer[bytesread] = 0;
#if DEBUG
        debug( "Read '%s' - feeding to %s".printf( ((string)buffer).escape( "" ), Type.from_instance( parser ).name() ) );
#endif
        parser.feed( (string)buffer, bytesread );
    }

    public bool onParserHaveCommand()
    {
        return false; // NMEA is not interactive
    }

    public bool onParserIsExpectedPrefix( string line )
    {
        return false;
    }

    public void onParserSolicitedCompleted( string[] response )
    {
        assert_not_reached();
    }

    public void onParserUnsolicitedCompleted( string[] response )
    {
        transport.logger.info( "URC: %s".printf( FsoFramework.StringHandling.stringListToString( response ) ) );
        urchandler( "", response[0], null );
    }

    public void onModemStatusChanged( FsoGps.AbstractReceiver receiver, int status )
    {
        if ( status == FsoGps.AbstractReceiver.Status.INITIALIZING )
        {
            /*
            var cmds = modem.commandSequence( "init" );
            foreach( var cmd in cmds )
            {
                debug( "sending cmd '%s'", cmd );
                enqueueAsyncYielding( new NullAtCommand(), cmd );
            }
            */
        }

    }
}

// vim:ts=4:sw=4:expandtab

