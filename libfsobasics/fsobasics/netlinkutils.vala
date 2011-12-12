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
 **/

namespace FsoFramework { namespace Net {

public string ipv4AddressForInterface( string iface )
{
    var socket = new Netlink.Socket();
    socket.connect( Linux.Netlink.NETLINK_ROUTE );

    Netlink.LinkCache link_cache;
    socket.link_alloc_cache( Linux.Socket.AF_UNSPEC, out link_cache );
    Netlink.AddrCache addr_cache;
    socket.addr_alloc_cache( out addr_cache );

    var ifindex = link_cache.name2i( iface );
#if DEBUG
    message( "index = %u", ifindex );
#endif
    var routeaddr = new Netlink.RouteAddress();
    //routeaddr.set_family( Posix.AF_INET );
    routeaddr.set_ifindex( ifindex );

    var ipv4 = "unknown";

    addr_cache.foreach_filter( routeaddr, (element) => {
#if DEBUG
        message( "called w/ object %p", element );
#endif
        unowned Netlink.Address addr = ( (Netlink.RouteAddress)element ).get_local();
#if DEBUG
        message( "addr: family: %d length: %d prefixlen: %d", addr.get_family(), addr.get_len(), addr.get_prefixlen() );
        message( "addr: %s", addr.to_string() );
#endif

        if ( addr.get_len() == 4 )
        {

            uint32 binaddress = *( (uint32*) addr.get_binary_addr() );

            // NOTE: We're using here our own InAddr structure as if we use the default
            // one vala ships we get the following compilation error:
            //
            // netlinkutils.vala:58.35-58.48: error: `Posix.InAddr' does not have a default constructor
            //     Posix.InAddr inaddr = Posix.InAddr();
            //
            // When this bug is fixed upstream we should use Posix.InAddr instead of
            // Posix.InAddr2 again.
            var inaddr = Posix.InAddr2();
            inaddr.s_addr = Posix.ntohl( binaddress );

            ipv4 = Posix.inet_ntoa( (Posix.InAddr) inaddr );
        }
    } );

    routeaddr.put();

    return ipv4;
}

} /* namespace Net */
} /* namespace FsoFramework */

// vim:ts=4:sw=4:expandtab
