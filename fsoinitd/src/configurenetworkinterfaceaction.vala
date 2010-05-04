/**
 * Copyright (C) 2010 Simon Busch <morphis@gravedo.de>
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

namespace FsoInit {
	
public enum RouteType
{
    DEFAULT,
    NET,
    HOST
}

public string routeTypeToString (RouteType type) 
{
	var result = "<unknown>";
	switch (type) 
	{
	case RouteType.DEFAULT:
		result = "DEFAULT";
		break;
	case RouteType.NET:
		result = "NET";
		break;
	case RouteType.HOST:
		result = "HOST";
		break;
	default:
		break;
	}
	return result;
}

public class ConfigureNetworkInterfaceAction : IAction, GLib.Object
{
	public string name { get { return "ConfigureNetworkInterfaceAction"; } }
	public string iface { get; set; }
	public string address { get; set; }
	public string netmask { get; set; }
	public RouteType routeType { get; set; }
	public string gateway { get; set; }

	public ConfigureNetworkInterfaceAction.with_settings(string iface, string address, string netmask)
	{
		this.iface = iface;
		this.address = address;
		this.netmask = netmask;
	}

	public string to_string() 
	{
		string tmp = @"[$(name)] :: ";
		tmp += @"iface='$(iface)' ";
		tmp += @"address='$(address)' ";
		tmp += @"netmask='$(netmask)' ";
		tmp += @"routeType='$(routeTypeToString(routeType))' ";
		tmp += @"gateway='$(gateway)'";
		return tmp;
	}

	private bool configureInterfaceWithAddress( string iface, string address, string netmask )
	{
		var socketfd = Posix.socket( Posix.AF_INET, Posix.SOCK_DGRAM, 0 );
		CHECK( () => { return socketfd > -1; }, "Can't create socket" );

		// set ip address
		Posix.InAddr inaddr = { 0 };
		var res = Linux.inet_aton( address, out inaddr );
		CHECK( () => { return res > -1; }, @"Can't convert address $address" );

		Posix.SockAddrIn addr = { 0 };
		addr.sin_family = Posix.AF_INET;
		addr.sin_addr.s_addr = inaddr.s_addr;

		var ifreq = Linux.Network.IfReq();
		Memory.copy( ifreq.ifr_name, iface, iface.length );
		Memory.copy( &ifreq.ifr_addr, &addr, sizeof( Posix.SockAddrIn ) );

		res = Posix.ioctl( socketfd, Linux.Network.SIOCSIFADDR, &ifreq );
		CHECK( () => { return res > -1; }, @"Can't set address $address on $iface" );

		// set ip netmask
		res = Linux.inet_aton( netmask, out inaddr );
		CHECK( () => { return res > -1; }, @"Can't convert address $netmask" );
		addr.sin_addr.s_addr = inaddr.s_addr;

		Memory.copy( &ifreq.ifr_netmask, &addr, sizeof( Posix.SockAddrIn ) );
		res = Posix.ioctl( socketfd, Linux.Network.SIOCSIFNETMASK, &ifreq );
		CHECK( () => { return res > -1; }, @"Can't set netmask $netmask on $iface" );

		// bring it up
		res = Posix.ioctl( socketfd, Linux.Network.SIOCGIFFLAGS, &ifreq );
		CHECK( () => { return res > -1; }, @"Can't get interface flags for $iface" );
		ifreq.ifr_flags |= Linux.Network.IfFlag.UP;
		res = Posix.ioctl( socketfd, Linux.Network.SIOCSIFFLAGS, &ifreq );
		CHECK( () => { return res > -1; }, @"Can't set interface flags for $iface" );

		return true;
	}

    private bool setRouteOnInterface( RouteType type, string address, string iface, string gateway = "" )
	{
		return false;
	}
	
	public void run() throws ActionError
	{
		configureInterfaceWithAddress(iface, address, netmask);
		setRouteOnInterface(routeType, address, iface, gateway);
	}

	public void reset() throws ActionError
	{
	}
}

public delegate bool Predicate();

public bool CHECK( Predicate p, string message, bool abort = false )
{
	if ( p() )
	{
		return true;
	}

	FsoFramework.theLogger.error( @"$message: $(strerror(errno))" );

	if ( abort )
	{
		Posix.exit( -1 );
	}

	return false;
}

} // namespace


