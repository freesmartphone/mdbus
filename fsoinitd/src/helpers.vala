/**
 * -- freesmartphone.org boot utility --
 *
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 **/

using GLib;

public enum RouteType
{
    DEFAULT,
    NET,
    HOST
}

/**
 * @class Hair
 **/
internal class Hair
{
    Posix.Stat structstat;
    bool writable;              // whether the root file system is currently writable

    public bool isPresent( string filename )
    {
        return ( Posix.stat( filename, out structstat ) != -1 );
    }

    public bool createDirectory( string filename, Posix.mode_t mode )
    {
        return ( Posix.mkdir( filename, mode ) != -1 );
    }

    public bool mountFilesystem( string source, string target, string type, Linux.MountFlags flags )
    {
        return ( Linux.mount( source, target, type, flags ) != -1 );
    }

    public bool mountFilesystemAt( Posix.mode_t mode, string source, string target, string type, Linux.MountFlags flags )
    {
        if ( !isPresent( target ) )
        {
            assert( DEBUG( @"$target is not present, trying to create..." ) );
            if ( !createDirectory( target, mode ) )
            {
                ERROR( @"Can't create $target: $(strerror(errno))" );
                return false;
            }
        }
        return mountFilesystem( source, target, type, flags );
    }

    public bool configureInterfaceWithAddress( string iface, string address, string netmask )
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

        res = Linux.ioctl( socketfd, Linux.Network.SIOCSIFADDR, &ifreq );
        CHECK( () => { return res > -1; }, @"Can't set address $address on $iface" );

        // set ip netmask
        res = Linux.inet_aton( netmask, out inaddr );
        CHECK( () => { return res > -1; }, @"Can't convert address $netmask" );
        addr.sin_addr.s_addr = inaddr.s_addr;

        Memory.copy( &ifreq.ifr_netmask, &addr, sizeof( Posix.SockAddrIn ) );
        res = Linux.ioctl( socketfd, Linux.Network.SIOCSIFNETMASK, &ifreq );
        CHECK( () => { return res > -1; }, @"Can't set netmask $netmask on $iface" );

        // bring it up
        res = Linux.ioctl( socketfd, Linux.Network.SIOCGIFFLAGS, &ifreq );
        CHECK( () => { return res > -1; }, @"Can't get interface flags for $iface" );
        ifreq.ifr_flags |= Linux.Network.IfFlag.UP;
        res = Linux.ioctl( socketfd, Linux.Network.SIOCSIFFLAGS, &ifreq );
        CHECK( () => { return res > -1; }, @"Can't set interface flags for $iface" );

        return true;
    }

    public bool setRouteOnInterface( RouteType type, string address, string iface, string gateway = "" )
    {
        return false;
    }

    public bool launchProcess( string cmdline )
    {
        Posix.system( cmdline );
        return true;
    }

    public bool launchProcessInBackground( string cmdline )
    {
        Posix.system( @"$cmdline &" );
        return true;
    }
}

public delegate bool Predicate();

public bool CHECK( Predicate p, string message, bool abort = false )
{
    if ( p() )
    {
        return true;
    }

    INFO( @"$message: $(strerror(errno))" );

    if ( abort )
    {
        Posix.exit( -1 );
    }

    return false;
}

/**
 * log
 **/
public bool DEBUG( string message )
{
    stdout.printf( @"$(TimeVal().to_iso8601()) FSO-BOOT: [DEBUG] $message\n" );
    return true;
}

public bool INFO( string message )
{
    stdout.printf( @"$(TimeVal().to_iso8601()) FSO-BOOT: [INFO]  $message\n" );
    return true;
}

public void ERROR( string message )
{
    stdout.printf( @"$(TimeVal().to_iso8601()) FSO-BOOT: [ERROR] $message\n" );
    Posix.exit( -1 );
}
