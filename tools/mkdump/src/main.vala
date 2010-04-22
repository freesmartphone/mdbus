/*
 * This file is part of mkdump
 *
 * (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 */

//===========================================================================
using GLib;
using FsoFramework;

MainLoop loop;

//===========================================================================
public void onKObjectEvent( HashTable<string,string> properties )
{
    stdout.printf( "[KOBJECT]\n" );
    foreach ( var key in properties.get_keys() )
    {
        stdout.printf( @"$key = $(properties.lookup(key))\n" );
    }
}

//===========================================================================
public void onNetlinkEvent( HashTable<string,string> properties )
{
    stdout.printf( "[NETLINK]\n" );
    foreach ( var key in properties.get_keys() )
    {
        stdout.printf( @"$key = $(properties.lookup(key))\n" );
    }
}

//===========================================================================
public void dump( string typ )
{
    if ( typ != "netlink" )
    {
        BaseKObjectNotifier.addMatch( "add", "*", onKObjectEvent );
        BaseKObjectNotifier.addMatch( "change", "*", onKObjectEvent );
        BaseKObjectNotifier.addMatch( "remove", "*", onKObjectEvent );
        stdout.printf( "Listening for kobject notifications...\n" );
    }

    /*
    if ( typ != "kobject" )
    {
        BaseNetlinkNotifier.addMatch( Linux.Netlink.RtMessageType.NEWROUTE, onNetlinkEvent );
        stdout.printf( "Listening for netlink notifications...\n" );
    }
    */
}

//===========================================================================
public int main( string[] args )
{
    if ( args.length == 2 && args[1].has_prefix( "--h" ) )
    {
        stdout.printf( "Usage:\nmkdump [all|kobject|netlink] - Dump kernel Messages.\n" );
        return 0;
    }
    var command = args[1] ?? "all";
    dump( command );
    
    loop = new MainLoop( null, false );
    loop.run();

    return 0;
}

