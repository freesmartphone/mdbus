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

public class FsoFramework.CrespoModemTransport : FsoFramework.BaseTransport
{
    private const uint MAX_BUFFER_SIZE = 0x1000;

    public CrespoModemTransport( string portname )
    {
        base( portname );
    }

    public override bool open()
    {
        fd = Posix.open( name, Posix.O_RDWR ) ; // | Posix.O_NDELAY );
        if ( fd == -1 )
        {
            logger.warning( "could not open %s: %s".printf( name, Posix.strerror( Posix.errno ) ) );
            return false;
        }

        configure();

        return base.open();
    }

    protected override ssize_t _real_write( int fd, void *data, int len )
    {
        var modem_data = Crespo.ModemData();

        modem_data.size = len;
        modem_data.data = new uint8[len];
        Memory.copy( modem_data.data, data, len );

        var rc = Linux.ioctl( fd, Crespo.ModemIoctlType.SEND, modem_data );

        if ( rc < 0 )
        {
            logger.error( @"Can't issue IOCTL_MODEM_SEND ioctl to modem dev node!" );
            return 0; // send HUP signal
        }

        return (ssize_t) len;
    }

    protected override ssize_t _real_read( int fd, void *data, int len )
    {
        if ( len < MAX_BUFFER_SIZE )
        {
            logger.warning( @"Can't receive modem response as read buffer is too small!" );
            return 0; // send HUP signal
        }

        var modem_data = Crespo.ModemData();
        modem_data.data = new uint8[MAX_BUFFER_SIZE];

        var  rc = Linux.ioctl( fd, Crespo.ModemIoctlType.RECV, modem_data );
        if ( rc < 0 )
        {
            logger.error( @"Can't issue IOCTL_MODEM_RECV ioctl to modem dev node!" );
            return 0; // send HUP signal
        }

        Memory.copy( data, modem_data.data, modem_data.size );

        free( modem_data.data );

        return (ssize_t) len;
    }

    public override int writeAndRead( uchar* wdata, int wlength, uchar* rdata, int rlength, int maxWait = 5000 )
    {
        return 0;
    }

    public override string repr()
    {
        return "<Crespo %s (fd %d)>".printf( name, fd );
    }

    /**
     * We override the configure method here to be sure no configure options are set by
     * anyone.
     **/
    protected override void configure() { }

    /**
     * This will suspend the transport. After it is suspend we can't send any more bytes
     * to the remote side.
     **/
    public override bool suspend()
    {
        assert( logger.debug(@"Successfully suspended the transport!") );
        return true;
    }

    /**
     * Resume the transport so we can send and receive our bytes again.
     **/
    public override void resume()
    {
        assert( logger.debug(@"Successfully resumed transport!") );
    }
}

// vim:ts=4:sw=4:expandtab
