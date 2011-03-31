/*
 * Copyright (C) 2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
 */

using GLib;

using FsoGsm;

/**
 * @class Pdp.PppInternal
 *
 * Pdp Handler implemented with the internal PPP stack
 **/
class Pdp.PppInternal : FsoGsm.PdpHandler
{
    public const string MODULE_NAME = "fsogsm.pdp_ppp_internal";

    private FsoFramework.Transport transport;
    private ThirdParty.At.PPP ppp;
    private IOChannel iochannel;

    public override string repr()
    {
        return "<>";
    }

    construct
    {
    }

    public void onDebugFromAtPPP( string str )
    {
        assert( logger.debug( @"ThirdParty.At.PPP: $str" ) );
    }

    public void onConnectFromAtPPPP( string iface, string local, string peer, string dns1, string dns2 )
    {
        logger.info( @"PPP stack now online via $iface. Local IP is $local, remote IP is $peer, DNS1 is $dns1, DNS2 is $dns2" );
        connectedWithNewDefaultRoute( iface, local, "255.255.255.0", peer, dns1, dns2 );
    }

    public void onDisconnectFromAtPPP( ThirdParty.At.PPP.DisconnectReason reason )
    {
        logger.info( @"PPP stack now offline. Disconnect reason is $reason" );
        this.sc_deactivate();
        disconnected();
    }

    public async override void sc_activate() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var m = theModem as FsoGsm.AbstractModem;

        var data = theModem.data();

        if ( data.contextParams == null )
        {
            disconnected();
            throw new FreeSmartphone.Error.INTERNAL_ERROR( "Context parameters not set" );
        }

        if ( data.contextParams.apn == null )
        {
            disconnected();
            throw new FreeSmartphone.Error.INTERNAL_ERROR( "APN not set" );
        }

        if ( ( (FsoGsm.AbstractModem) theModem ).data_transport != "serial" &&  ( (FsoGsm.AbstractModem) theModem ).data_transport != "tcp" )
        {
            disconnected();
            throw new FreeSmartphone.Error.INTERNAL_ERROR( "ippp only supports data transport types 'serial' and 'tcp' for now" );
        }

        transport = FsoFramework.Transport.create( m.data_transport, m.data_port, m.data_speed );
        var channel = new AtChannel( null, transport, new FsoGsm.StateBasedAtParser() );

        if ( !yield channel.open() )
        {
            disconnected();
            throw new FreeSmartphone.Error.SYSTEM_ERROR( "Can't open data channel or transport" );
        }

        var delay = config.intValue( MODULE_NAME, "post_open_delay", 500 );
        Timeout.add( delay, sc_activate.callback );
        yield;

        //var response = yield channel.enqueueAsync( new FsoGsm.CustomAtCommand(), "E0" );
        var response = yield channel.enqueueAsync( new FsoGsm.CustomAtCommand(), "+CGQREQ=1;+CGQMIN=1;+CGEQREQ=1;+CGEQMIN=1" );

        response = yield channel.enqueueAsync( new FsoGsm.CustomAtCommand(), "+CGDCONT=1,\"IP\",\"%s\",,0,0".printf( data.contextParams.apn ) );
        if ( ! response[0].strip().has_suffix( "OK" ) )
        {
            yield channel.close();
            transport = null;
            disconnected();
            throw new FreeSmartphone.Error.SYSTEM_ERROR( "Can't initialize data transport" );
        }
        response = yield channel.enqueueAsync( new FsoGsm.CustomAtCommand(), "+CGACT=1" );
        if ( ! response[0].strip().has_suffix( "OK" ) )
        {
            yield channel.close();
            transport = null;
            disconnected();
            throw new FreeSmartphone.Error.SYSTEM_ERROR( "Can't initialize data transport" );
        }
        response = yield channel.enqueueAsync( new FsoGsm.CustomAtCommand(), "D*99***1#" );
        if ( ! response[0].strip().has_suffix( "CONNECT" ) )
        {
            yield channel.close();
            transport = null;
            disconnected();
            throw new FreeSmartphone.Error.SYSTEM_ERROR( "Can't initialize data transport" );
        }

        iochannel = new IOChannel.unix_new( transport.freeze() );

        delay = config.intValue( MODULE_NAME, "post_connect_delay", 500 );
        Timeout.add( delay, sc_activate.callback );
        yield;

        ppp = new ThirdParty.At.PPP( iochannel );
        ppp.set_debug( onDebugFromAtPPP );
        ppp.set_recording( "/tmp/ppp.log" );
        ppp.set_credentials( data.contextParams.username, data.contextParams.password );
        ppp.set_connect_function( onConnectFromAtPPPP );
        ppp.set_disconnect_function( onDisconnectFromAtPPP );
        ppp.open();
    }

    public async override void sc_deactivate()
    {
        ppp = null;
        iochannel = null;
        transport.close();
        transport = null;
        iochannel = null;
    }

    public async override void statusUpdate( string status, GLib.HashTable<string,Variant> properties )
    {
        assert_not_reached();
    }
}

static string sysfs_root;
static string devfs_root;

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    FsoFramework.theLogger.debug( "pdp_ppp_internal fso_factory_function" );
    // grab sysfs paths
    var config = FsoFramework.theConfig;
    sysfs_root = config.stringValue( "cornucopia", "sysfs_root", "/sys" );
    devfs_root = config.stringValue( "cornucopia", "devfs_root", "/dev" );

    return Pdp.PppInternal.MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    // do not remove this function
}
