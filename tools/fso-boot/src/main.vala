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

const string ROOTFS_PROC_NAME = "/proc";
const Posix.mode_t ROOTFS_PROC_MODE = (Posix.mode_t) 0555;

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

    private bool mountFilesystem( string source, string target, string type, Linux.MountFlags flags = 0 )
    {
        return ( Linux.mount( source, target, type, flags ) != -1 );
    }

    private void bringupFilesystems()
    {
        // 1.) We need the mountpoint /proc to be present, otherwise the rest won't work
        if ( !isPresent( "/proc" ) )
        {
            assert( DEBUG( "/proc is not present, trying to create..." ) );
            if ( !createDirectory( ROOTFS_PROC_NAME, ROOTFS_PROC_MODE ) )
            {
                ERROR( @"/proc is not present and can't be created: $(strerror(errno))" );
            }
        }
        assert( DEBUG( "/proc is present, trying to mount procfs..." ) );

        // 2.) Mount procfs
        if ( !mountFilesystem( "proc", "/proc", "proc" ) )
        {
            ERROR( @"Can't mount procfs: $(strerror(errno))" );
        }
        assert( DEBUG( "procfs mounted successfully" ) );

        // 3.) Mount everything in /etc/fstab
    }

    private void bringupNetworking()
    {
    }

    private void bringupDBus()
    {
    }

    public void run()
    {
        bringupFilesystems();
        bringupNetworking();
        bringupDBus();
    }
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

