/*
 * This file is part of mkdump
 *
 * (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
public void onKObjectEvent( string action, HashTable<string,string> properties )
{
    stdout.printf( "---------------------------------------------\n" );
    stdout.printf( @"[KOBJECT] $action:\n" );
    foreach ( var key in properties.get_keys() )
    {
        stdout.printf( @"$key = $(properties.lookup(key))\n" );
    }
}

//===========================================================================
public void onNetlinkEvent( string action, HashTable<string,string> properties )
{
    stdout.printf( "---------------------------------------------\n" );
    stdout.printf( @"[NETLINK] $action:\n" );
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
        BaseKObjectNotifier.addMatch( "add", "*", (properties) => { onKObjectEvent( "ADD", properties ); } );
        BaseKObjectNotifier.addMatch( "change", "*", (properties) => { onKObjectEvent( "CHANGE", properties ); } );
        BaseKObjectNotifier.addMatch( "remove", "*", (properties) => { onKObjectEvent( "REMOVE", properties ); } );
        stdout.printf( "Listening for kobject notifications...\n" );
    }

    if ( typ != "kobject" )
    {
        BaseNetlinkNotifier.addMatch( Linux.Netlink.RtMessageType.NEWLINK, (properties) => { onNetlinkEvent( "NEWLINK", properties ); } );
        BaseNetlinkNotifier.addMatch( Linux.Netlink.RtMessageType.DELLINK, (properties) => { onNetlinkEvent( "DELLINK", properties ); } );
        BaseNetlinkNotifier.addMatch( Linux.Netlink.RtMessageType.GETLINK, (properties) => { onNetlinkEvent( "GETLINK", properties ); } );
        BaseNetlinkNotifier.addMatch( Linux.Netlink.RtMessageType.SETLINK, (properties) => { onNetlinkEvent( "SETLINK", properties ); } );
        BaseNetlinkNotifier.addMatch( Linux.Netlink.RtMessageType.NEWADDR, (properties) => { onNetlinkEvent( "NEWADDR", properties ); } );
        BaseNetlinkNotifier.addMatch( Linux.Netlink.RtMessageType.DELADDR, (properties) => { onNetlinkEvent( "DELADDR", properties ); } );
        BaseNetlinkNotifier.addMatch( Linux.Netlink.RtMessageType.GETADDR, (properties) => { onNetlinkEvent( "GETADDR", properties ); } );
        BaseNetlinkNotifier.addMatch( Linux.Netlink.RtMessageType.NEWROUTE, (properties) => { onNetlinkEvent( "NEWROUTE", properties ); } );
        BaseNetlinkNotifier.addMatch( Linux.Netlink.RtMessageType.DELROUTE, (properties) => { onNetlinkEvent( "DELROUTE", properties ); } );
        BaseNetlinkNotifier.addMatch( Linux.Netlink.RtMessageType.GETROUTE, (properties) => { onNetlinkEvent( "GETROUTE", properties ); } );
        BaseNetlinkNotifier.addMatch( Linux.Netlink.RtMessageType.NEWNEIGH, (properties) => { onNetlinkEvent( "NEWNEIGH", properties ); } );
        BaseNetlinkNotifier.addMatch( Linux.Netlink.RtMessageType.DELNEIGH, (properties) => { onNetlinkEvent( "DELNEIGH", properties ); } );
        BaseNetlinkNotifier.addMatch( Linux.Netlink.RtMessageType.GETNEIGH, (properties) => { onNetlinkEvent( "GETNEIGH", properties ); } );
        BaseNetlinkNotifier.addMatch( Linux.Netlink.RtMessageType.NEWRULE, (properties) => { onNetlinkEvent( "NEWRULE", properties ); } );
        BaseNetlinkNotifier.addMatch( Linux.Netlink.RtMessageType.DELRULE, (properties) => { onNetlinkEvent( "DELRULE", properties ); } );
        BaseNetlinkNotifier.addMatch( Linux.Netlink.RtMessageType.GETRULE, (properties) => { onNetlinkEvent( "GETRULE", properties ); } );
        BaseNetlinkNotifier.addMatch( Linux.Netlink.RtMessageType.NEWQDISC, (properties) => { onNetlinkEvent( "NEWQDISC", properties ); } );
        BaseNetlinkNotifier.addMatch( Linux.Netlink.RtMessageType.DELQDISC, (properties) => { onNetlinkEvent( "DELQDISC", properties ); } );
        BaseNetlinkNotifier.addMatch( Linux.Netlink.RtMessageType.GETQDISC, (properties) => { onNetlinkEvent( "GETQDISC", properties ); } );
        BaseNetlinkNotifier.addMatch( Linux.Netlink.RtMessageType.NEWTCLASS, (properties) => { onNetlinkEvent( "NEWTCLASS", properties ); } );
        BaseNetlinkNotifier.addMatch( Linux.Netlink.RtMessageType.DELTCLASS, (properties) => { onNetlinkEvent( "DELTCLASS", properties ); } );
        BaseNetlinkNotifier.addMatch( Linux.Netlink.RtMessageType.GETTCLASS, (properties) => { onNetlinkEvent( "GETTCLASS", properties ); } );
        BaseNetlinkNotifier.addMatch( Linux.Netlink.RtMessageType.NEWTFILTER, (properties) => { onNetlinkEvent( "NEWTFILTER", properties ); } );
        BaseNetlinkNotifier.addMatch( Linux.Netlink.RtMessageType.DELTFILTER, (properties) => { onNetlinkEvent( "DELTFILTER", properties ); } );
        BaseNetlinkNotifier.addMatch( Linux.Netlink.RtMessageType.GETTFILTER, (properties) => { onNetlinkEvent( "GETTFILTER", properties ); } );
        BaseNetlinkNotifier.addMatch( Linux.Netlink.RtMessageType.NEWACTION, (properties) => { onNetlinkEvent( "NEWACTION", properties ); } );
        BaseNetlinkNotifier.addMatch( Linux.Netlink.RtMessageType.DELACTION, (properties) => { onNetlinkEvent( "DELACTION", properties ); } );
        BaseNetlinkNotifier.addMatch( Linux.Netlink.RtMessageType.GETACTION, (properties) => { onNetlinkEvent( "GETACTION", properties ); } );
        BaseNetlinkNotifier.addMatch( Linux.Netlink.RtMessageType.NEWPREFIX, (properties) => { onNetlinkEvent( "NEWPREFIX", properties ); } );
        BaseNetlinkNotifier.addMatch( Linux.Netlink.RtMessageType.GETMULTICAST, (properties) => { onNetlinkEvent( "GETMULTICAST", properties ); } );
        BaseNetlinkNotifier.addMatch( Linux.Netlink.RtMessageType.GETANYCAST, (properties) => { onNetlinkEvent( "GETANYCAST", properties ); } );
        BaseNetlinkNotifier.addMatch( Linux.Netlink.RtMessageType.NEWNEIGHTBL, (properties) => { onNetlinkEvent( "NEWNEIGHTBL", properties ); } );
        BaseNetlinkNotifier.addMatch( Linux.Netlink.RtMessageType.GETNEIGHTBL, (properties) => { onNetlinkEvent( "GETNEIGHTBL", properties ); } );
        BaseNetlinkNotifier.addMatch( Linux.Netlink.RtMessageType.SETNEIGHTBL, (properties) => { onNetlinkEvent( "SETNEIGHTBL", properties ); } );
        stdout.printf( "Listening for netlink notifications...\n" );
    }
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

// vim:ts=4:sw=4:expandtab
