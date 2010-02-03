/**
 * -- freesmartphone.org boot utility --
 *
 * Copyright (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

const string DBUS_BUS_NAME  = "org.freedesktop.DBus";
const string DBUS_OBJ_PATH  = "/";
const string DBUS_INTERFACE = "org.freedesktop.DBus";
const string DBUS_INTERFACE_INTROSPECTABLE = "org.freedesktop.DBus.Introspectable";

const string PROCFS_NAME = "/proc";
const Posix.mode_t PROCFS_MODE = (Posix.mode_t) 0555;

const string SYSFS_NAME = "/sys";
const Posix.mode_t SYSFS_MODE = (Posix.mode_t) 0755;

/**
 * @class Muenchhausen
 **/
internal class Muenchhausen
{
    Posix.Stat structstat;
    bool writable;              // whether the root file system is currently writable

    private bool isPresent( string filename )
    {
        return ( Posix.stat( filename, out structstat ) != -1 );
    }

    private bool createDirectory( string filename, Posix.mode_t mode )
    {
        return ( Posix.mkdir( filename, mode ) != -1 );
    }

    private bool mountFilesystem( string source, string target, string type, Linux.MountFlags flags )
    {
        return ( Linux.mount( source, target, type, flags ) != -1 );
    }

    private bool mountFilesystemAt( Posix.mode_t mode, string source, string target, string type, Linux.MountFlags flags )
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

    private bool configureInterfaceWithAddress( string iface, string address, string netmask )
    {
        var socketfd = Posix.socket( Posix.AF_INET, Posix.SOCK_DGRAM, 0 );
        CHECK( () => { return socketfd > -1; }, "Can't create socket" );

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
        CHECK( () => { return res > -1; }, @"Can't set address" );

        res = Posix.ioctl( socketfd, Linux.Network.SIOCGIFFLAGS, &ifreq );
        CHECK( () => { return res > -1; }, @"Can't get interface flags for $iface" );
        ifreq.ifr_flags |= Linux.Network.IfFlag.UP;
        res = Posix.ioctl( socketfd, Linux.Network.SIOCSIFFLAGS, &ifreq );
        CHECK( () => { return res > -1; }, @"Can't set interface flags for $iface" );

        return true;
    }

    private void bringupFilesystems()
    {
        mountFilesystemAt( (Posix.mode_t) 0555, "proc", "/proc", "proc", Linux.MountFlags.MS_SILENT );
        mountFilesystemAt( (Posix.mode_t) 0755, "sys", "/sys", "sysfs", Linux.MountFlags.MS_SILENT | Linux.MountFlags.MS_NOEXEC | Linux.MountFlags.MS_NODEV | Linux.MountFlags.MS_NOSUID );
        mountFilesystemAt( (Posix.mode_t) 0755, "devpts", "/dev/pts", "devpts", Linux.MountFlags.MS_SILENT | Linux.MountFlags.MS_NOEXEC | Linux.MountFlags.MS_NODEV | Linux.MountFlags.MS_NOSUID );
    }

    private void bringupNetworking()
    {
        configureInterfaceWithAddress( "lo", "127.0.0.1", "255.255.255.0" );

        //Posix.system( "ifconfig lo up" );
        //Posix.system( "ifconfig usb0 192.168.0.200/24 up" );
        //Posix.system( "route add default usb0" );
    }

    private void bringupDBus()
    {
        //Posix.system( "dbus-daemon --system" );
    }

    private void bringupGetty()
    {
        Posix.system( "/sbin/getty 38400 tty0 &" );
    }

    public void run()
    {
        bringupFilesystems();
        bringupNetworking();
        bringupDBus();
        bringupGetty();
    }
}

internal delegate bool Predicate();

internal bool CHECK( Predicate p, string message, bool abort = false )
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
internal bool DEBUG( string message )
{
    stdout.printf( @"$(TimeVal().to_iso8601()) FSO-BOOT: [DEBUG] $message\n" );
    return true;
}

internal bool INFO( string message )
{
    stdout.printf( @"$(TimeVal().to_iso8601()) FSO-BOOT: [INFO]  $message\n" );
    return true;
}

internal void ERROR( string message )
{
    stdout.printf( @"$(TimeVal().to_iso8601()) FSO-BOOT: [ERROR] $message\n" );
    Posix.exit( -1 );
}

/**
 * main entry point
 **/
int main( string[] args )
{
    INFO( "starting" );
    var muenchhausen = new Muenchhausen();
    Idle.add( () => {
        muenchhausen.run();
        return false;
    } );

    var loop = new MainLoop();
    loop.run();

    return 0;
}

