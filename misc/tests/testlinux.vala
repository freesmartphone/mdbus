using GLib;

int main( string[] args )
{
    var host = new char[512];
    var service = new char[512];

    Linux.Network.IfAddrs iaddrs;
    if ( Linux.Network.getifaddrs( out iaddrs ) == 0 )
    {
        print( "OK\n" );

        //uint32 binaddr = Posix.ntohl( ( (Posix.SockAddrIn*)addrs.ifa_addr).sin_addr.s_addr );
        //Posix.InAddr inaddr = { binaddr };

        for ( unowned Linux.Network.IfAddrs addrs = iaddrs; addrs != null; addrs = addrs.ifa_next )
        {
            var name = addrs.ifa_name;
            var family = ( (Posix.SockAddrIn*)addrs.ifa_addr).sin_family;
            print( @"Interface: $name has address with family $family\n" );

            if ( family == Posix.AF_INET )
            {
                int result = Posix.getnameinfo( addrs.ifa_addr, (Posix.socklen_t) sizeof( Posix.SockAddrIn ), host, service, 0 );
                if ( result == 0 )
                {
                    print( @"Address = %s\n", (string) host );
                }
            }

        }
    }
    else
    {
        print( "FAIL\n" );
    }





    return 0;
}

// vim:ts=4:sw=4:expandtab
