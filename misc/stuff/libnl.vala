public string[] ipv4ForInterface( string iface )
{
    var socket = new Netlink.Socket();
    socket.connect( Linux.Netlink.NETLINK_ROUTE );

    Netlink.LinkCache link_cache;
    socket.link_alloc_cache( out link_cache );
    Netlink.AddrCache addr_cache;
    socket.addr_alloc_cache( out addr_cache );

    var ifindex = link_cache.name2i( iface );

    message( "index = %u", ifindex );

    var routeaddr = new Netlink.RouteAddress();
    //routeaddr.set_family( Posix.AF_INET );
    routeaddr.set_ifindex( ifindex );

    addr_cache.foreach_filter( routeaddr, (element) => {
	message( "called w/ object %p", element );
	unowned Netlink.Address addr = ( (Netlink.RouteAddress)element ).get_local();

	/*
	uint32 binaddress = *( (uint32*) addr.get_binary_addr() );
	binaddress = Posix.ntohl( binaddress );
	var inaddr = Posix.InAddr() { s_addr = Posix.ntohl( binaddress ) };
	message( "got object %s", Posix.inet_ntoa( inaddr ) );
	*/

	message( "addr: family: %d length: %d prefixlen: %d", addr.get_family(), addr.get_len(), addr.get_prefixlen() );
	message( "addr: %s", addr.to_string() );
    } );

    routeaddr.put();

    return { };
}

void main()
{
    var ips = ipv4ForInterface( "wlan0" );
}

// vim:ts=4:sw=4:expandtab
