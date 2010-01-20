/**
 * Copyright (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

public delegate void FsoFramework.NetlinkNotifierFunc( HashTable<string, string> properties );

[Compact]
internal class NetlinkDelegateHolder
{
    public FsoFramework.NetlinkNotifierFunc func;
    public NetlinkDelegateHolder( FsoFramework.NetlinkNotifierFunc func )
    {
        this.func = func;
    }
}

/**
 * @class FsoFramework.BaseNetlinkNotifier
 **/
public class FsoFramework.BaseNetlinkNotifier : Object
{
    public static BaseNetlinkNotifier instance;

    public Netlink.LinkCache cache;
    public Netlink.Socket socket;

    private int fd = -1;
    private uint watch;
    private IOChannel channel;

    private char[] buffer;

    private const ssize_t BUFFER_LENGTH = 4096;

    private HashTable<uint16, List<NetlinkDelegateHolder>> map;

    public BaseNetlinkNotifier()
    {
        buffer = new char[BUFFER_LENGTH];

        map = new HashTable<uint16, List<NetlinkDelegateHolder>>( direct_hash, direct_equal );

        socket = new Netlink.Socket();
        socket.disable_seq_check();
        socket.modify_cb( Netlink.CallbackType.VALID, Netlink.CallbackKind.CUSTOM, handleNetlinkMessage );

        socket.connect( Linux.Netlink.NETLINK_ROUTE );
        socket.link_alloc_cache( out cache );
        cache.mngt_provide();

        var res = socket.add_memberships( Linux.Netlink.RTNLGRP_LINK, Linux.Netlink.RTNLGRP_IPV4_IFADDR, Linux.Netlink.RTNLGRP_IPV4_ROUTE );
        assert( res != -1 );

        fd = socket.get_fd();
        assert( fd != -1 );
        channel = new IOChannel.unix_new( fd );
        watch = channel.add_watch( IOCondition.IN | IOCondition.HUP, onActionFromSocket );
    }

    ~BaseNetlinkNotifier()
    {
        if ( watch != 0 )
            Source.remove( watch );

        if ( fd != -1 )
            Posix.close( fd );
    }

    protected bool onActionFromSocket( IOChannel source, IOCondition condition )
    {
        if ( ( condition & IOCondition.HUP ) == IOCondition.HUP )
        {
            error( "HUP on netlink route socket, will no longer get any notifications" );
            return false;
        }

        if ( ( condition & IOCondition.IN ) == IOCondition.IN )
        {
            assert( fd != -1 );
            socket.recvmsgs_default();
            return true;
        }

        critical( "Unsupported IOCondition %u", (int)condition );
        return true;
    }

    protected int handleNetlinkMessage( Netlink.Message msg )
    {
        Netlink.MessageHeader hdr = msg.header();
        debug( "received netlink message w/ type %d", hdr.nlmsg_type );

        var res = msg.parse( ( obj ) => {
            handleMessage( hdr.nlmsg_type );
            var params = Netlink.DumpParams() { dp_type = Netlink.DumpType.STATS,
                                                dp_fd = Posix.stdout,
                                                dp_dump_msgtype = true };
            obj.dump( params );
        } );
        
        if ( res < 0 )
        {
            debug( Netlink.strerror( res ) );
        }
        return Netlink.CallbackAction.STOP;
    }

    protected void handleMessage( uint16 type )
    {
        var properties = new HashTable<string, string>( str_hash, str_equal );
        /*
        foreach ( var part in parts )
        {
            message( "%s", part );
            var elements = part.split( "=" );
            if ( elements.length == 2 )
            {
                properties.insert( elements[0], elements[1] );
            }
        }
        */

        weak List<weak NetlinkDelegateHolder> list = map.lookup( type );
        if ( list != null )
        {
            foreach( var delegateholder in list )
            {
                delegateholder.func( properties );
            }
        }
    }

    protected void _addMatch( uint16 type, NetlinkNotifierFunc callback )
    {
        weak List<NetlinkDelegateHolder> list = map.lookup( type );
        if ( list == null )
        {
            List<NetlinkDelegateHolder> newlist = new List<NetlinkDelegateHolder>();
            newlist.append( new NetlinkDelegateHolder( callback ) );
#if DEBUG
            debug( @"# delegates for action $action and subsystem $subsystem now $(newlist.length())" );
#endif
            map.insert( type, (owned) newlist );
        }
        else
        {
            list.append( new NetlinkDelegateHolder( callback ) );
#if DEBUG
            debug( @"# delegates for action $action and subsystem $subsystem now $(list.length())" );
#endif
        }
    }

    //
    // public API
    //
    public static void addMatch( uint16 action, NetlinkNotifierFunc callback )
    {
        if ( BaseNetlinkNotifier.instance == null )
            BaseNetlinkNotifier.instance = new BaseNetlinkNotifier();

        BaseNetlinkNotifier.instance._addMatch( (uint16)action, callback );
    }

}

