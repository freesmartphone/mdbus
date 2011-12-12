/*
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
        socket.link_alloc_cache( Linux.Socket.AF_UNSPEC, out cache );
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
            FsoFramework.theLogger.error( "HUP on netlink route socket, will no longer get any notifications" );
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
#if DEBUG
        debug( "received netlink message w/ type %d", hdr.nlmsg_type );
#endif
        msg.parse( ( obj ) => {
            handleMessage( hdr.nlmsg_type, obj );
        } );
        return Netlink.CallbackAction.STOP;
    }

    protected void handleMessage( uint16 type, Netlink.Object obj )
    {
        var properties = new HashTable<string, string>( str_hash, str_equal );

        switch ( type )
        {
            case Linux.Netlink.RtMessageType.NEWLINK:
            case Linux.Netlink.RtMessageType.DELLINK:
            case Linux.Netlink.RtMessageType.GETLINK:
            case Linux.Netlink.RtMessageType.SETLINK:
                fillLinkProperties( (Netlink.Link) obj, ref properties );
                break;

            case Linux.Netlink.RtMessageType.NEWROUTE:
            case Linux.Netlink.RtMessageType.DELROUTE:
            case Linux.Netlink.RtMessageType.GETROUTE:
                fillRouteProperties( (Netlink.Route) obj, ref properties );
                break;

            case Linux.Netlink.RtMessageType.NEWADDR:
            case Linux.Netlink.RtMessageType.DELADDR:
            case Linux.Netlink.RtMessageType.GETADDR:
                fillAddressProperties( (Netlink.Address) obj, ref properties);
                break;

            case Linux.Netlink.RtMessageType.NEWNEIGH:
            case Linux.Netlink.RtMessageType.DELNEIGH:
            case Linux.Netlink.RtMessageType.GETNEIGH:
                fillNeighbourProperties( (Netlink.Neighbour) obj, ref properties );
                break;

            case Linux.Netlink.RtMessageType.NEWRULE:
            case Linux.Netlink.RtMessageType.DELRULE:
            case Linux.Netlink.RtMessageType.GETRULE:
                fillRuleProperties( (Netlink.Rule) obj, ref properties );
                break;

            case Linux.Netlink.RtMessageType.NEWNEIGHTBL:
            case Linux.Netlink.RtMessageType.GETNEIGHTBL:
            case Linux.Netlink.RtMessageType.SETNEIGHTBL:
                // no get functions for the properties of struct neightbl :-/
            case Linux.Netlink.RtMessageType.NEWQDISC:
            case Linux.Netlink.RtMessageType.DELQDISC:
            case Linux.Netlink.RtMessageType.GETQDISC:
            case Linux.Netlink.RtMessageType.NEWTCLASS:
            case Linux.Netlink.RtMessageType.DELTCLASS:
            case Linux.Netlink.RtMessageType.GETTCLASS:
            case Linux.Netlink.RtMessageType.NEWTFILTER:
            case Linux.Netlink.RtMessageType.DELTFILTER:
            case Linux.Netlink.RtMessageType.GETTFILTER:
            case Linux.Netlink.RtMessageType.NEWACTION:
            case Linux.Netlink.RtMessageType.DELACTION:
            case Linux.Netlink.RtMessageType.GETACTION:
            case Linux.Netlink.RtMessageType.NEWPREFIX:
            case Linux.Netlink.RtMessageType.GETMULTICAST:
            case Linux.Netlink.RtMessageType.GETANYCAST:
            default:
                FsoFramework.theLogger.warning( @"missing fillProperties for netlink message type $type" );
                break;
        }

        weak List<weak NetlinkDelegateHolder> list = map.lookup( type );
        if ( list != null )
        {
            foreach( var delegateholder in list )
            {
                delegateholder.func( properties );
            }
        }
    }

    protected void fillLinkProperties( Netlink.Link lnk, ref HashTable<string, string> properties )
    {
        properties.insert( "LINK_NAME", lnk.get_name() );
        properties.insert( "LINK_IFINDEX", lnk.get_ifindex().to_string() );
        properties.insert( "LINK_FAMILY", Netlink.af2Str( lnk.get_family(), buffer ) );
        properties.insert( "LINK_TYPE", Netlink.llproto2Str( lnk.get_arptype(), buffer ) );
        var addr = lnk.get_addr();
        if ( addr != null )
            properties.insert( "LINK_ADDRESS", addr.to_string() );
        var bcast = lnk.get_broadcast();
        if ( bcast != null )
            properties.insert( "LINK_BROADCAST", bcast.to_string() );
        properties.insert( "LINK_MTU", lnk.get_mtu().to_string() );
        properties.insert( "LINK_TXQUEUELEN", lnk.get_txqlen().to_string() );
        properties.insert( "LINK_WEIGHT", lnk.get_weight().to_string() );
        properties.insert( "LINK_FLAGS", Netlink.linkFlags2Str( lnk.get_flags(), buffer ) );
        var qdisc = lnk.get_qdisc();
        if ( qdisc != null )
            properties.insert( "LINK_QDISC", qdisc );
//
//	if (link->ce_mask & LINK_ATTR_LINK) {
//		struct rtnl_link *ll = rtnl_link_get(cache, link->l_link);
//
//		nl_dump_line(p, "LINK_LINK_IFINDEX=%d\n", link->l_link);
//		if (ll) {
//			nl_dump_line(p, "LINK_LINK_IFNAME=%s\n", ll->l_name);
//			rtnl_link_put(ll);
//		}
//	}
//
//	if (link->ce_mask & LINK_ATTR_MASTER) {
//		struct rtnl_link *master = rtnl_link_get(cache, link->l_master);
//		nl_dump_line(p, "LINK_MASTER=%s\n",
//			     master ? master->l_name : "none");
//		if (master)
//			rtnl_link_put(master);
//	}
//
//	if (link->ce_mask & LINK_ATTR_STATS) {
//		for (i = 0; i <= RTNL_LINK_STATS_MAX; i++) {
//			char *c = buf;
//
//			sprintf(buf, "LINK_");
//			rtnl_link_stat2str(i, buf + 5, sizeof(buf) - 5);
//			while (*c) {
//				*c = toupper(*c);
//				c++;
//			}
//			nl_dump_line(p, "%s=%" PRIu64 "\n", buf, link->l_stats[i]);
//		}
//	}
//
    }

    protected void fillRouteProperties( Netlink.Route route, ref HashTable<string, string> properties)
    {
        properties.insert( "ROUTE_FAMILY", Netlink.af2Str( route.get_family(), buffer ) );
        var dst = route.get_dst();
        if ( dst != null )
            properties.insert( "ROUTE_DST", dst.to_string() );
        var src = route.get_src();
        if ( src != null )
            properties.insert( "ROUTE_SRC", src.to_string() );
        var prefsrc = route.get_pref_src();
        if ( prefsrc != null )
            properties.insert( "ROUTE_PREFSRC", prefsrc.to_string() );
        var iif = cache.i2name( route.get_iif(), buffer );
        if ( iif != null )
            properties.insert( "ROUTE_IIF", iif );
        properties.insert( "ROUTE_TOS", route.get_tos().to_string() );
        properties.insert( "ROUTE_TABLE", route.get_table().to_string() );
        properties.insert( "ROUTE_SCOPE", Netlink.routeScope2Str( route.get_scope(), buffer ) );
        properties.insert( "ROUTE_PRIORITY", route.get_priority().to_string() );
        properties.insert( "ROUTE_TYPE", Netlink.routeType2Str( route.get_type(), buffer ) );

	//if (route->ce_mask & ROUTE_ATTR_MULTIPATH) {
	//	struct rtnl_nexthop *nh;
	//	int index = 1;

	//	if (route->rt_nr_nh > 0)
	//		nl_dump_line(p, "ROUTE_NR_NH=%u\n", route->rt_nr_nh);

	//	nl_list_for_each_entry(nh, &route->rt_nexthops, rtnh_list) {
	//		p->dp_ivar = index++;
	//		rtnl_route_nh_dump(nh, p);
	//	}
    }

    protected void fillAddressProperties( Netlink.Address addr, ref HashTable<string, string> properties )
    {
        properties.insert( "ADDR_FAMILY", Netlink.af2Str( addr.get_family(), buffer ) );

        var local = addr.get_local();
        if ( local != null )
            properties.insert( "ADDR_LOCAL", local.to_string() );
        var peer = addr.get_peer();
        if ( peer != null )
            properties.insert( "ADDR_PEER", peer.to_string() );
        var bcast = addr.get_broadcast();
        if ( bcast != null )
            properties.insert( "ADDR_BROADCAST", bcast.to_string() );
        var a = addr.get_anycast();
        if ( a != null )
            properties.insert( "ADDR_ANYCAST", a.to_string() );
        a = addr.get_multicast();
        if ( a != null )
            properties.insert( "ADDR_MULTICAST", a.to_string() );
        properties.insert( "ADDR_PREFIXLEN", addr.get_prefixlen().to_string() );
        properties.insert( "ADDR_IFINDEX", addr.get_ifindex().to_string() );
        properties.insert( "ADDR_IFNAME", cache.i2name( addr.get_ifindex(), buffer ) );
        properties.insert( "ADDR_SCOPE", Netlink.routeScope2Str( addr.get_scope(), buffer ) );
        properties.insert( "ADDR_LABEL", addr.get_label() );
        properties.insert( "ADDR_FLAGS", Netlink.addrFlags2Str( addr.get_flags(), buffer ) );

//	if (addr->ce_mask & ADDR_ATTR_CACHEINFO) {
//		struct rtnl_addr_cacheinfo *ci = &addr->a_cacheinfo;
//
//		nl_dump_line(p, "ADDR_CACHEINFO_VALID=%s\n",
//			     ci->aci_valid == 0xFFFFFFFFU ? "forever" :
//			     nl_msec2str(ci->aci_valid * 1000,
//					   buf, sizeof(buf)));
//
//		nl_dump_line(p, "ADDR_CACHEINFO_PREFERED=%s\n",
//			     ci->aci_prefered == 0xFFFFFFFFU ? "forever" :
//			     nl_msec2str(ci->aci_prefered * 1000,
//					 buf, sizeof(buf)));
//
//		nl_dump_line(p, "ADDR_CACHEINFO_CREATED=%s\n",
//			     nl_msec2str(addr->a_cacheinfo.aci_cstamp * 10,
//					 buf, sizeof(buf)));
//
//		nl_dump_line(p, "ADDR_CACHEINFO_LASTUPDATE=%s\n",
//			     nl_msec2str(addr->a_cacheinfo.aci_tstamp * 10,
//					 buf, sizeof(buf)));
//	}
    }

    protected void fillNeighbourProperties( Netlink.Neighbour neigh, ref HashTable<string, string> properties )
    {
        properties.insert( "NEIGH_FAMILY", Netlink.af2Str( neigh.get_family(), buffer ) );
        var a = neigh.get_lladdr();
        if ( a != null )
            properties.insert( "NEIGH_LLADDR", a.to_string() );
        a = neigh.get_dst();
        if ( a != null )
            properties.insert( "NEIGH_DST", a.to_string() );
        properties.insert( "NEIGH_IFINDEX", neigh.get_ifindex().to_string() );
        properties.insert( "NEIGH_IFNAME", cache.i2name( neigh.get_ifindex(), buffer ) );
        properties.insert( "NEIGH_TYPE", Netlink.routeType2Str( neigh.get_type(), buffer ) );
        properties.insert( "NEIGH_FLAGS", Netlink.neighFlags2Str( neigh.get_flags(), buffer ) );
        properties.insert( "NEIGH_STATE", Netlink.neighState2Str( neigh.get_state(), buffer ) );
    }


    protected void fillRuleProperties( Netlink.Rule rule, ref HashTable<string, string> properties )
    {
        properties.insert( "RULE_PRIORITY", rule.get_prio().to_string() );
        properties.insert( "RULE_FAMILY", Netlink.af2Str( rule.get_family(), buffer ) );
        var a = rule.get_dst();
        if ( a != null )
            properties.insert( "RULE_DST", a.to_string() );

//	if (rule->ce_mask & RULE_ATTR_DST_LEN)
//		nl_dump_line(p, "RULE_DSTLEN=%u\n", rule->r_dst_len);

        a = rule.get_src();
        if ( a != null )
            properties.insert( "RULE_SRC", a.to_string() );

//	if (rule->ce_mask & RULE_ATTR_SRC_LEN)
//		nl_dump_line(p, "RULE_SRCLEN=%u\n", rule->r_src_len);

        properties.insert( "RULE_IIF", rule.get_iif() );

//	if (rule->ce_mask & RULE_ATTR_TABLE)
//		nl_dump_line(p, "RULE_TABLE=%u\n", rule->r_table);

        properties.insert( "RULE_REALM", rule.get_realms().to_string() );
        properties.insert( "RULE_MARK", "0x%llx".printf( rule.get_mark() ) );
        properties.insert( "RULE_DSFIELD", rule.get_dsfield().to_string() );

//	if (rule->ce_mask & RULE_ATTR_TYPE)
//		nl_dump_line(p, "RULE_TYPE=%s\n",
//			     nl_rtntype2str(rule->r_type, buf, sizeof(buf)));

//	if (rule->ce_mask & RULE_ATTR_SRCMAP)
//		nl_dump_line(p, "RULE_SRCMAP=%s\n",
//			     nl_addr2str(rule->r_srcmap, buf, sizeof(buf)));
    }

    protected void fillQdiscProperties( Netlink.Qdisc qdisc, ref HashTable<string, string> properties )
    {
    }

    protected void _addMatch( uint16 type, NetlinkNotifierFunc callback )
    {
        weak List<NetlinkDelegateHolder> list = map.lookup( type );
        if ( list == null )
        {
            List<NetlinkDelegateHolder> newlist = new List<NetlinkDelegateHolder>();
            newlist.append( new NetlinkDelegateHolder( callback ) );
#if DEBUG
            debug( @"# delegates for type $type is now $(newlist.length())" );
#endif
            map.insert( type, (owned) newlist );
        }
        else
        {
            list.append( new NetlinkDelegateHolder( callback ) );
#if DEBUG
            debug( @"# delegates for type $type is now $(list.length())" );
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

// vim:ts=4:sw=4:expandtab

