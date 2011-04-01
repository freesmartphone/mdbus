/**
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
using Linux.Termios;

//===========================================================================
public class FsoFramework.SerialTransport : FsoFramework.BaseTransport
//===========================================================================
{
    public bool dtr_cycle;

    public SerialTransport( string portname,
                            uint portspeed,
                            bool raw = true,
                            bool hard = true )
    {
        base( portname, portspeed, raw, hard );

        dtr_cycle = false;
    }

    private bool set_dtr( bool on )
    {
        int bits = TIOCM_DTR;
        int rc;

        rc = Posix.ioctl( fd, ( on ? TIOCMBIS : TIOCMBIC ), bits );
        if ( rc < 0 )
        {
            logger.warning( "could not set dtr bit for serial transport: %s".printf( Posix.strerror( Posix.errno ) ) );
            return false;
        }

        return true;
    }

    public override bool open()
    {
        fd = Posix.open( name, Posix.O_RDWR | Posix.O_NOCTTY | Posix.O_NONBLOCK );
        if ( fd == -1 )
        {
            logger.warning( "could not open %s: %s".printf( name, Posix.strerror( Posix.errno ) ) );
            return false;
        }

        configure();

        if ( dtr_cycle )
        {
            set_dtr( false );
            Posix.sleep( 1 );
            set_dtr( true );
        }

        return base.open();
    }

    public override string repr()
    {
        return "<Serial %s@%u (fd %d)>".printf( name, speed, fd );
    }

}

