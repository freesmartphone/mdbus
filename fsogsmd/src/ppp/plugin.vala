/*
 * Copyright (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 **/

using GLib;
using FsoFramework;

DBus.Connection dbus_conn;
FreeSmartphone.GSM.PDP fsogsmd_pdp;

static async void fsogsmd_report_status( HashTable<string,Value?> properties )
{
    try
    {
        yield fsogsmd_pdp.internal_status_update( PPPD.phase.to_string(), properties );
    }
    catch ( FreeSmartphone.GSM.Error e0 )
    {
        PPPD.error( @"Can't report status to fsogsmd: $(e0.message)" );
    }
    catch ( FreeSmartphone.Error e1 )
    {
        PPPD.error( @"Can't report status to fsogsmd: $(e1.message)" );
    }
    catch ( DBus.Error e2 )
    {
        PPPD.error( @"Can't report status to fsogsmd: $(e2.message)" );
    }
}

static void fsogsmd_on_phase_change( int arg )
{
    PPPD.info( @"on_phase_change: $arg" );
    fsogsmd_report_status( new HashTable<string,Value?>( str_hash, str_equal ) );
}

static void fsogsmd_on_ip_up( int arg )
{
    PPPD.info( "on_ip_up" );
    var ouraddr = PPPD.IPCP.gotoptions[0].ouraddr;
    if ( ouraddr == 0 )
    {
        PPPD.info( "on_ip_up: ouraddr is empty; can't proceed" );
        assert_not_reached();
    }

    string iface = (string) PPPD.ifname;

    var properties = new HashTable<string,Value?>( str_hash, str_equal );
    properties.insert( "iface", iface );
    properties.insert( "local", ouraddr );

    var fantasyaddr = Posix.htonl( 0x0a404040 + PPPD.ifunit );
    var hisaddr = PPPD.IPCP.gotoptions[0].hisaddr;
    var dns1 = PPPD.IPCP.gotoptions[0].dnsaddr[0];
    var dns2 = PPPD.IPCP.gotoptions[0].dnsaddr[1];
    /* Prefer the peer options remote address first, _unless_ pppd made the
     * address up, at which point prefer the local options remote address,
     * and if that's not right, use the made-up address as a last resort.
     */
    var peer_hisaddr = PPPD.IPCP.hisoptions[0].hisaddr;

    PPPD.info( "on_ip_up: our remote address is %u, his remote address is %u", hisaddr, peer_hisaddr );

    if ( peer_hisaddr != 0 && ( peer_hisaddr != fantasyaddr ) )
    {
        properties.insert( "gateway", peer_hisaddr );
    }
    else if ( hisaddr != 0 )
    {
        properties.insert( "gateway", hisaddr );
    }
    else if ( peer_hisaddr == fantasyaddr )
    {
        properties.insert( "gateway", fantasyaddr );
    }
    else
    {
        assert_not_reached();
    }
    if ( dns1 != 0 )
    {
        properties.insert( "dns1", dns1 );
    }
    if ( dns2 != 0 )
    {
        properties.insert( "dns2", dns2 );
    }
    fsogsmd_report_status( properties );
}

static void fsogsmd_on_exit( int arg )
{
    PPPD.info( "on_exit" );
}

static int fsogsmd_get_chap_check()
{
    PPPD.info( "get_chap_check" );
    return 1; // we support CHAP
}

static int fsogsmd_get_pap_check()
{
    PPPD.info( "get_pap_check" );
    return 1; // we support PAP
}

static int fsogsmd_get_credentials( string username, string password )
{
    PPPD.info( "get_credentials" );
    if ( username != null && password == null )
    {
	// pppd is checking pap support; return 1 for supported
	return 1;
    }

    //FIXME: Get credentials from fsogsmd

    username = "";
    password = "";

    return 1;
}

static void plugin_init()
{
    PPPD.info( "fsogsmd plugin init" );
    PPPD.add_notifier( PPPD.phasechange, fsogsmd_on_phase_change );
    PPPD.add_notifier( PPPD.exitnotify, fsogsmd_on_exit );
    PPPD.add_notifier( PPPD.ip_up_notifier, fsogsmd_on_ip_up );

    PPPD.chap_passwd_hook = fsogsmd_get_credentials;
    PPPD.chap_check_hook = fsogsmd_get_chap_check;
    PPPD.pap_passwd_hook = fsogsmd_get_credentials;
    PPPD.pap_check_hook = fsogsmd_get_pap_check;

    try
    {

        dbus_conn = DBus.Bus.get( DBus.BusType.SYSTEM );

        fsogsmd_pdp = dbus_conn.get_object(
            FsoFramework.GSM.ServiceDBusName,
            FsoFramework.GSM.DeviceServicePath,
            FsoFramework.GSM.ServiceFacePrefix + ".PDP" ) as FreeSmartphone.GSM.PDP;
    }
    catch ( DBus.Error e )
    {
        PPPD.error( @"DBus Error while initializing plugin: $(e.message)" );
    }
}
