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
public class FsoFramework.SocketTransport : FsoFramework.BaseTransport
//===========================================================================
{
    private int domain;
    private int stype;
    private uint port;

    public SocketTransport( string type, string host, uint port )
    {
        base( host, 115200 );
        this.port = port;

        switch ( type )
        {
            case "unix":
                domain = Posix.AF_UNIX;
                stype = Posix.SOCK_STREAM;
                break;
            case "udp":
                domain = Posix.AF_INET;
                stype = Posix.SOCK_DGRAM;
                break;
            case "tcp":
                domain = Posix.AF_INET;
                stype = Posix.SOCK_STREAM;
                break;
            default:
                assert_not_reached();
        }
    }

    public override string getName()
    {
        return ( port > 0 ) ? "%s:%u".printf( base.getName(), port ) : base.getName();
    }

    public override string repr()
    {
        return "<Socket Transport %s (fd %d)>".printf( getName(), fd );
    }

    public override bool open()
    {
        fd = Posix.socket( domain, stype, 0 );
        if ( fd == -1 )
        {
            warning( "could not create socket: %s".printf( Posix.strerror( Posix.errno ) ) );
            return false;
        }


        
        configure();

        return base.open();
    }
}

