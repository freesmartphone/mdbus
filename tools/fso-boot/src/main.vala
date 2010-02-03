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

/**
 * @class Muenchhausen
 **/
internal class Muenchhausen
{
    Hair h;

    public Muenchhausen()
    {
        h = new Hair();
    }

    private void bringupFilesystems()
    {
        h.mountFilesystemAt( (Posix.mode_t) 0555, "proc", "/proc", "proc", Linux.MountFlags.MS_SILENT );
        h.mountFilesystemAt( (Posix.mode_t) 0755, "sys", "/sys", "sysfs", Linux.MountFlags.MS_SILENT | Linux.MountFlags.MS_NOEXEC | Linux.MountFlags.MS_NODEV | Linux.MountFlags.MS_NOSUID );
        h.mountFilesystemAt( (Posix.mode_t) 0755, "devpts", "/dev/pts", "devpts", Linux.MountFlags.MS_SILENT | Linux.MountFlags.MS_NOEXEC | Linux.MountFlags.MS_NODEV | Linux.MountFlags.MS_NOSUID );
    }

    private void populateVolatile()
    {
    }

    private void bringupNetworking()
    {
        h.configureInterfaceWithAddress( "lo", "127.0.0.1", "255.255.255.0" );
        h.configureInterfaceWithAddress( "usb0", "192.168.0.202", "255.255.255.0" );
    }

    private void bringupDBus()
    {
        h.launchProcess( "dbus-daemon --system" );
    }

    private void bringupGetty()
    {
        h.launchProcessInBackground( "/sbin/getty 38400 tty0" );
    }

    public void run()
    {
        bringupFilesystems();
        populateVolatile();
        bringupNetworking();
        bringupDBus();
        bringupGetty();
    }
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

