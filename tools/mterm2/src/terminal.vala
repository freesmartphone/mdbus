/*
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

using GLib;
using FsoFramework;

const bool MAINLOOP_CALL_AGAIN = true;
const bool MAINLOOP_DONT_CALL_AGAIN = false;

const int BUFFER_SIZE = 8192;

char[] buffer;

//========================================================================//
public class Terminal : Object
//========================================================================//
{
    Transport transport;
    weak Options options;
    Reader reader;

    string transportname;
    string portname;

    public Terminal( Options option )
    {
        buffer = new char[BUFFER_SIZE];
        this.options = option;
    }

    public bool open()
    {
        if ( !parsePortspec() )
        {
            quitWithMessage( "FATAL: Can't parse portspec '%s'.".printf( options.portspec ) );
            return MAINLOOP_DONT_CALL_AGAIN;
        }

        switch ( transportname )
        {
            case "serial":
                transport = new SerialTransport( portname, options.portspeed );
                break;
            case "abyss":
                transport = new AbyssTransport( portname.to_int() );
                break;
            case "unix":
                transport = new SocketTransport( "unix", portname, 0 );
                break;
            case "tcp":
            case "udp":
                transport = new SocketTransport( transportname, portname, options.portspeed );
                break;
            default:
                quitWithMessage( "FATAL: Unknown transport method '%s'.".printf( transportname ) );
                return MAINLOOP_DONT_CALL_AGAIN;
        }
        transport.setDelegates( onTransportRead, onTransportHup );
        transport.open();

        if ( !transport.isOpen() )
        {
            quitWithMessage( "FATAL: Cannot open %s: %s".printf( options.portspec, Posix.strerror( Posix.errno ) ) );
            return MAINLOOP_DONT_CALL_AGAIN;
        }

        reader = new Reader( transport );

        return MAINLOOP_DONT_CALL_AGAIN;
    }

    public bool parsePortspec()
    {
        if ( ":" in options.portspec )
        {
            var elements = options.portspec.split( ":" );
            if ( elements.length != 2 )
                return false;

            transportname = elements[0];
            portname = elements[1];
        }
        else
        {
            transportname = "serial";
            portname = options.portspec;
        }
        return true;
    }

    public void onTransportRead( Transport transport )
    {
        int numread = transport.read( buffer, BUFFER_SIZE-1 );
        buffer[numread] = 0;
        stdout.printf( "%s", (string)buffer );
    }

    public void onTransportHup( Transport transport )
    {
        quitWithMessage( "FATAL: Peer closed connection." );
    }

}
