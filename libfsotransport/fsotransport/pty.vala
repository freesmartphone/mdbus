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
public class FsoFramework.PtyTransport : FsoFramework.BaseTransport
//===========================================================================
{
    private char[] ptyname = new char[1024]; // PATH_MAX?

    public PtyTransport()
    {
        base( "Pty", 115200 );
    }

    public override string getName()
    {
        return (string)ptyname;
    }

    public override string repr()
    {
        return "<PTY %s (fd %d)>".printf( getName(), fd );
    }

    public override bool open()
    {
        fd = Posix.posix_openpt( Posix.O_RDWR | Posix.O_NOCTTY | Posix.O_NONBLOCK );
        if ( fd == -1 )
        {
            logger.warning( "could not open %s: %s".printf( name, Posix.strerror( Posix.errno ) ) );
            return false;
        }

        Posix.grantpt( fd );
        Posix.unlockpt( fd );
        Linux.Termios.ptsname_r( fd, ptyname );

        int flags = Posix.fcntl( fd, Posix.F_GETFL );
        int res = Posix.fcntl( fd, Posix.F_SETFL, flags | Posix.O_NONBLOCK );
        if ( res < 0 )
        {
            logger.warning( "can't set pty master to NONBLOCK: %s".printf( Posix.strerror( Posix.errno ) ) );
        }

        configure();

        return base.open();
    }
}

