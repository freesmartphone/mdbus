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

using Posix;

namespace FsoFramework.Network
{
    public errordomain Error
    {
        INTERNAL_ERROR,
    }

    // FIXME should be in linux.vapi
    private static const uint IFNAMSIZ = 16;
    private static const uint IFF_UP = 0x1;

    public class Interface
    {
        private int fd;
        private string name;

        // FIXME dirty trick to get the correct header files included. If we remove this
        // netinet/in.h is not included which is needed by linux/if.h
        private SockAddrIn dummy;

        private bool check_flags( uint flags ) throws FsoFramework.Network.Error
        {
            var ifr = Linux.Network.IfReq();
            strncpy( (string) ifr.ifr_name, this.name, IFNAMSIZ );
            ifr.ifr_name[ IFNAMSIZ - 1 ] = '\0';

            var rc = ioctl( fd, Linux.Network.SIOCGIFFLAGS, &ifr);
            if ( rc == -1 )
            {
                throw new FsoFramework.Network.Error.INTERNAL_ERROR( "Could not process ioctl to gather interface status" );
            }

            return (bool) ( ifr.ifr_flags & flags );
        }

        /**
         * Set flags for interface. With @param set you specify the flag you want to set
           and with @param clr the flag you want to unset.
         **/
        private bool set_flags(uint set, uint clr)
        {
            var ifr = Linux.Network.IfReq();
            strncpy( (string) ifr.ifr_name, this.name, IFNAMSIZ );
            ifr.ifr_name[ IFNAMSIZ - 1 ] = '\0';

            var rc = ioctl( fd, Linux.Network.SIOCSIFFLAGS, &ifr);
            if ( rc == -1 )
            {
                return false;
            }

            ifr.ifr_flags = ( ifr.ifr_flags & ( ~clr ) ) | set;
            rc = ioctl( fd, Linux.Network.SIOCSIFFLAGS, &ifr );
            return rc != -1;
        }

        public Interface( string name ) throws FsoFramework.Network.Error
        {
            this.name = name;

            fd = socket( AF_INET, SOCK_DGRAM, 0 );
            if ( fd < 0 )
            {
                throw new Error.INTERNAL_ERROR( "Could not create socket for interface configuration" );
            }
        }

        /**
         * Will bring the interface up if it is down before.
         **/
        public void up() throws FsoFramework.Network.Error
        {
            if ( !set_flags( IFF_UP, 0 ) )
            {
                throw new FsoFramework.Network.Error.INTERNAL_ERROR( @"Could not bring interface $name up!" );
            }
        }

        public bool is_up() throws FsoFramework.Network.Error
        {
            return check_flags( IFF_UP );
        }

        /**
         * Will bring the interface down if it is up before.
         **/
        public void down() throws FsoFramework.Network.Error
        {
            if ( !set_flags( 0, IFF_UP ) )
            {
                throw new FsoFramework.Network.Error.INTERNAL_ERROR( @"Could not bring interface $name down!" );
            }

        }

        /**
         * If you're finish with interface configuration this will cleanup and close open
         * sockets.
         **/
        public void finish()
        {
            if ( fd > 0 )
            {
                close( fd );
                fd = -1;
            }
        }
    }
}
