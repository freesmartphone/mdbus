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

    /**
     * @class Interface
     *
     * Wraps a Linux network interface using ioctls to implement access.
     *
     * Eventually this should use the netlink APIs rather than ioctls.
     **/
    public class Interface
    {
        protected int fd;
        protected string name;
        protected int index;

        //
        // private
        //

        private bool check_flags( uint flags ) throws FsoFramework.Network.Error
        {
            var ifr = Linux.Network.IfReq();
            ifr.ifr_ifindex = this.index;

            if ( ioctl( fd, Linux.Network.SIOCGIFNAME, &ifr ) < 0 )
            {
                throw new FsoFramework.Network.Error.INTERNAL_ERROR( @"Could not set interface name " +
                                                                      "for request: $(Posix.strerror(Posix.errno))" );
            }

            if ( ioctl( fd, Linux.Network.SIOCGIFFLAGS, &ifr ) < 0 )
            {
                throw new FsoFramework.Network.Error.INTERNAL_ERROR( @"Could not process ioctl to gather " +
                                                                      "interface status: $(Posix.strerror(Posix.errno))" );
            }

            return (bool) ( ifr.ifr_flags & flags );
        }

        /**
         * Set flags for interface. With @param set you specify the flag you want to set
           and with @param clr the flag you want to unset.
         **/ 
        private bool set_flags( uint set, uint clr )
        {
            var ifr = Linux.Network.IfReq();
            ifr.ifr_ifindex = this.index;

            if ( ioctl( fd, Linux.Network.SIOCGIFNAME, &ifr ) < 0 )
            {
                throw new FsoFramework.Network.Error.INTERNAL_ERROR( @"Could not set interface name " +
                                                                      "for request: $(Posix.strerror(Posix.errno))" );
            }

            if ( ioctl( fd, Linux.Network.SIOCSIFFLAGS, &ifr) < 0 )
                return false;

            ifr.ifr_flags = ( ifr.ifr_flags & ( ~clr ) ) | set;
            if ( ioctl( fd, Linux.Network.SIOCSIFFLAGS, &ifr ) < 0 )
                return false;

            return true;
        }

        private void setup_interface_index() throws FsoFramework.Network.Error
        {
            var ifr = Linux.Network.IfReq();

            // FIXME we need to use a pointer here as otherwise vala compiles this to
            // something like this:
            // struct ifreq ifr;
            // struct ifreq _tmp11_;
            // _tmp11_ = ifr; // no reference, direct copy ...
            // strncpy( _tmp11_.ifr_name, name, ...);
            var ifrp = (Linux.Network.IfReq*)(&ifr);
            strncpy( (string) ifrp->ifr_name, name, Linux.Network.INTERFACE_NAME_SIZE );

            var rc = ioctl( fd, Linux.Network.SIOCGIFINDEX, &ifr);
            if ( rc < 0 )
                throw new Error.INTERNAL_ERROR( @"Could not get index for interface $name: $(Posix.strerror(Posix.errno))" );

            this.index = ifr.ifr_ifindex;
        }

        //
        // public API
        //

        public Interface( string name ) throws FsoFramework.Network.Error
        {
            this.name = name;

            fd = socket( AF_INET, SOCK_DGRAM, 0 );
            if ( fd < 0 )
                throw new Error.INTERNAL_ERROR( @"Could not create socket for interface configuration: $(Posix.strerror(Posix.errno))" );

            setup_interface_index();
        }

        ~Interface()
        {
            finish();
        }

        /**
         * Will bring the interface up if it is down before.
         **/
        public void up() throws FsoFramework.Network.Error
        {
            if ( !set_flags( Linux.Network.IfFlag.UP, 0 ) )
            {
                throw new FsoFramework.Network.Error.INTERNAL_ERROR( @"Could not bring interface $name up: $(Posix.strerror(Posix.errno))" );
            }
        }

        public bool is_up() throws FsoFramework.Network.Error
        {
            return check_flags( Linux.Network.IfFlag.UP );
        }

        /**
         * Will bring the interface down if it is up before.
         **/
        public void down() throws FsoFramework.Network.Error
        {
            if ( !set_flags( 0, Linux.Network.IfFlag.UP ) )
            {
                throw new FsoFramework.Network.Error.INTERNAL_ERROR( @"Could not bring interface $name down: $(Posix.strerror(Posix.errno))" );
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

    /**
     * @class WextInterface
     *
     * Wraps a wireless interface using the Wireless Extension API (WEXT).
     *
     * This is actually already deprecated and we should rather implement
     * nl80211 as soon as possible.
     **/
    public class WextInterface : Interface
    {
        public WextInterface( string name ) throws FsoFramework.Network.Error
        {
            base( name );
        }

        public void set_power( bool on ) throws FsoFramework.Network.Error
        {
            var req = LinuxExt.WirelessExtensions.IwReq();

            // FIXME we need to use a pointer here as otherwise vala compiles this to
            // something like this:
            // struct iwreq wr;
            // struct iwreq _tmp11_;
            // _tmp11_ = iwr; // no reference, direct copy ...
            // strncpy( _tmp11_.ifrn_name, name, ...);
            var reqp = (LinuxExt.WirelessExtensions.IwReq*)(&req);
            strncpy( (string) reqp->ifr_name, name, Linux.Network.INTERFACE_NAME_SIZE );

            req.u.power.disabled = on ? 0 : 1;
            var rc = Posix.ioctl( fd, Linux.WirelessExtensions.SIOCSIWPOWER, &req );
            if ( rc < 0 )
                throw new FsoFramework.Network.Error.INTERNAL_ERROR(
                    @"Could not process ioctl for setting wireless power status of interface $(name)" );
        }
    }
}

// vim:ts=4:sw=4:expandtab
