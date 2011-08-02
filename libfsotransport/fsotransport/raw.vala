/*
 * Copyright (C) 2011 Simon Busch <morphis@gravedo.de>
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
public class FsoFramework.RawTransport : FsoFramework.BaseTransport
//===========================================================================
{
    public RawTransport( string portname )
    {
        base( portname );
    }

    public override bool open()
    {
        fd = Posix.open( name, Posix.O_RDWR );
        if ( fd == -1 )
        {
            logger.warning( "could not open %s: %s".printf( name, Posix.strerror( Posix.errno ) ) );
            return false;
        }

        configure();

        return base.open();
    }

    public override string repr()
    {
        return "<Raw %s@%u (fd %d)>".printf( name, speed, fd );
    }

    /**
     * Configure the high speed to be ready for sending and receiving bytes.
     **/
    protected override void configure()
    {
    }

    /**
     * This will suspend the transport. After it is suspend we can't send any more bytes
     * to the remote side.
     **/
    public bool suspend()
    {
        return true;
    }

    /**
     * Resume the transport so we can send and receive our bytes again.
     **/
    public void resume()
    {
    }
}

// vim:ts=4:sw=4:expandtab
