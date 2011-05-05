/*
 * Copyright (C) 2011 Simon Busch <morphis@gravedo.de>
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
using Posix;

public class FsoGsm.ModemHandler : FsoFramework.AbstractObject
{
    private const string DEFAUTL_IMSI = "262010123456789";

    private FreeSmartphone.Usage usage;
    private FreeSmartphone.GSM.SIM sim_service;
    private FreeSmartphone.GSM.PDP pdp_service;
    private FreeSmartphone.GSM.Device device_service;
    private FreeSmartphone.GSM.Network network_service;
    private FreeSmartphone.Data.World world_service;

    /* these are the parts we need as interface to the connman core */
    private Connman.Device? network_device;
    private Connman.Network? network;
    private Connman.IpAddress ipaddr;

    /* local informations about the modem state */    
    private FreeSmartphone.GSM.DeviceStatus modem_status;
    private bool initialized;
    private bool available;
    private bool supports_gprs;
    private int signal_strength;
    private string operator_name;
    private string mccmnc;

    /**
     * Reset internal data structure
     **/
    private void reset_internal_data()
    {
        available = false;
        signal_strength =  0;
        supports_gprs = false;
        operator_name = "";
    }

    /**
     * Signal handler for Usage service. Is triggered whenever a resource changes
     * its availability.
     **/
    private void on_resource_available( string name, bool availability )
    {
        if ( name == "GSM" )
        {
            if ( availability && !available )
            {
                on_gsm_resource_available();
            }
            else
            {
                available = false;
            }
        }
    }

    /**
     * Retrieve a dbus proxy for the supplied interface defintion from the FSO
     * GSM message bus.
     **/
    private T get_service<T>() throws GLib.Error
    {
        return Bus.get_proxy_sync<T>( BusType.SYSTEM, FsoFramework.GSM.ServiceDBusName,
                                      FsoFramework.GSM.DeviceServicePath, DBusProxyFlags.NONE );
    }

    /**
     * Try to find out if the modem supports gprs data connections.
     **/
    private async void check_gprs_support()
    {
        try
        {
            var features = yield device_service.get_features();
            supports_gprs = ( features.lookup( "pdp" ) != null );
        }
        catch ( Error err )
        {
            logger.error( @"Cannot check if modem supports gprs" );
        }
    }

    /**
     * Check modem for correct registration status
     **/
    private async void check_registration()
    {
        try
        {
            var device_status = yield device_service.get_device_status();
            if ( device_status <= FreeSmartphone.GSM.DeviceStatus.ALIVE_SIM_READY )
            {
                logger.info( @"Modem is not yet in ALIVE_REGISTERED state; aborting registration check ..." );
                return;
            }

            logger.debug( @"Modem is in ALIVE_REGISTERED state now; we can register our network device now" );

            if ( network != null )
            {
                logger.debug( @"We already have a network created for the curent device; ignoring ..." );
                return;
            }

            string imsi = network_device.get_ident();
            network = new Connman.Network( imsi, Connman.NetworkType.CELLULAR );
            if ( network == null )
            {
                logger.error( @"Could not create network provided by our current device" );
                return;
            }

            ipaddr.clear();

            network.set_group( "fsogsm" );
            network.set_available( true );
            network.set_associating( false );
            network.set_connected( false );
            network.set_index( -1 );
            network.set_string( "Operator", operator_name );
            network.set_strength( (uint8) signal_strength );

            network_device.add_network( network );

            logger.info( @"Successfully provided the network to the device" );
        }
        catch ( Error err )
        {
            logger.error( @"Cannot check modem registration status" );
        }
    }

    /**
     * Create a new default device and register it to the internal connman core.
     * The device can later identified by the IMSI supplied by the modem.
     **/
    private async bool create_device()
    {
        string imsi = DEFAUTL_IMSI;
        bool result = true;

        try
        {
            var info = yield sim_service.get_sim_info();
            imsi = info.lookup( "imsi" ) as string;
            if ( imsi == null )
            {
                imsi = DEFAUTL_IMSI;
            }

            // if we already have a network device registered with then unregister it
            // first before we create our new one
            if ( network_device != null )
            {
                network_device.unregister();
                network_device = null;
            }

            network_device = new Connman.Device( imsi, Connman.DeviceType.CELLULAR );
            if ( network_device == null )
            {
                return false;
            }

            // FIXME why do we have to set the identifier twice? (this is the way how it
            // is done in the ofono plugin)
            network_device.set_ident( imsi );

            if ( network_device.register() != 0 )
            {
                network_device = null;
            }
        }
        catch ( Error err )
        {
            logger.error( @"Can't create default network device: $(err.message)" );
            result = false;
        }

        check_registration();
        check_gprs_support();

        return result;
    }

    /**
     * When network status has changed extract relevant information and supply
     * it the our network object.
     **/
    private async void on_modem_network_status_changed( HashTable<string,Variant> status )
    {
        Variant? v0 = status.lookup( "provider" );
        operator_name = ( v0 == null ? "unknown" : v0.get_string() );

#if 0
        Variant? v1 = status.lookup( "strength" );
        logger.debug( @"$(v1.classify())" );
        signal_strength = ( v1 == null ? 0 : v1.get_int32() );
#endif

        Variant? v2 = status.lookup( "code" );
        mccmnc = ( v2 == null ? "" : v2.get_string() );

        if ( network != null )
        {
            network.set_strength( (uint8) signal_strength );
            network.set_string( "Operator", operator_name );
        }
    }

    /**
     * When device status has changed we have to register/remove our network
     * object from the connman core.
     **/
    private async void on_modem_device_status_changed( FreeSmartphone.GSM.DeviceStatus status )
    {
        logger.debug( @"Got modem status $(status)" );

        if ( status < modem_status && 
             status < FreeSmartphone.GSM.DeviceStatus.ALIVE_SIM_READY )
        {
            logger.debug( @"Removing network as modem is not ready anymore" );
            return;
        }

        switch ( status )
        {
            case FreeSmartphone.GSM.DeviceStatus.ALIVE_SIM_READY:
                if ( network_device == null )
                {
                    create_device();
                }
                break;
            case FreeSmartphone.GSM.DeviceStatus.ALIVE_REGISTERED:
                check_registration();
                break;
        }

        modem_status = status;
    }

    private async void on_gsm_resource_available()
    {
        try
        {
            yield usage.request_resource( "GSM" );
            available = true;

            device_service = get_service<FreeSmartphone.GSM.Device>();
            sim_service = get_service<FreeSmartphone.GSM.SIM>();
            network_service = get_service<FreeSmartphone.GSM.Network>();
            pdp_service = get_service<FreeSmartphone.GSM.PDP>();

            world_service = Bus.get_proxy_sync<FreeSmartphone.Data.World>( BusType.SYSTEM, FsoFramework.Data.ServiceDBusName,
                                                                          FsoFramework.Data.WorldServicePath,
                                                                          DBusProxyFlags.NONE );

            device_service.device_status.connect( on_modem_device_status_changed );
            network_service.status.connect( on_modem_network_status_changed );

            logger.info( @"Successfully registered with GSM resource" );

            var device_status = yield device_service.get_device_status();
            if ( device_status >= FreeSmartphone.GSM.DeviceStatus.ALIVE_SIM_READY )
            {
                create_device();
            }
        }
        catch ( Error err )
        {
            logger.error( @"Can't setup for using GSM resource: $(err.message)" );
        }
    }

    //
    // public API
    //

    public ModemHandler()
    {
        initialized = false;
    }

    public override string repr()
    {
        return "<>";
    }

    public async void initialize()
    {
        string[] resources = { };

        logger.info( "Initializing ..." );

        if ( initialized )
        {
            return;
        }

        reset_internal_data();

        try
        {
            usage = Bus.get_proxy_sync<FreeSmartphone.Usage>( BusType.SYSTEM, FsoFramework.Usage.ServiceDBusName,
                                                              FsoFramework.Usage.ServicePathPrefix,
                                                              DBusProxyFlags.NONE );
            usage.resource_available.connect( on_resource_available );

            resources = yield usage.list_resources();

            // if gsm resource is already available we can request it right now. Otherwise
            // we have to wait until the resource arrives on the bus.
            if ( "GSM" in resources )
            {
                on_gsm_resource_available();
            }
        }
        catch ( GLib.Error err )
        {
            logger.error( @"Can't register on usage service for listing to new resources" );
        }

        initialized = true;
    }

    /**
     * Establish PDP connection with registered network
     **/
    public async int connect_network()
    {
        logger.debug( @"Establishing GSM PDP connection ..." );

        if ( mccmnc.length == 0 )
        {
            logger.error( "We don't have mcc and mnc to retrieve correct APN for PDP connection" );
            return -EINVAL;
        }

        try
        {
            logger.debug( @"mccmnc = $(mccmnc)" );
            var apns = yield world_service.get_apns_for_mcc_mnc( mccmnc );
            if ( apns.length == 0 )
            {
                logger.error( "Invalid mcc and mnc wihtout context information!" );
                return -EINVAL;
            }

            var apn = apns[0];
            logger.debug( @"Using apn = \"$(apn.apn)\", username = \"$(apn.username)\", password = \"$(apn.password)\"");
            yield pdp_service.set_credentials( apn.apn, apn.username, apn.password );
            yield pdp_service.activate_context();
        }
        catch ( Error err )
        {
            logger.error( @"Failed to activate PDP connection: $(err.message)" );
            return -1;
        }

        // FIXME set ipaddr, method ...

        network.set_connected( true );

        return 0;
    }

    /**
     * Realse current active PDP connection
     **/
    public async int disconnect_network()
    {
        logger.debug( @"Releasing GSM PDP connection ..." );

        try
        {
            yield pdp_service.deactivate_context();
        }
        catch ( Error err )
        {
            logger.error( @"Failed to deactivate PDP connection: $(err.message)" );
            return -1;
        }

        network.set_connected( false );

        return 0;
    }

    public void shutdown()
    {
        logger.info( "Shuting down ..." );

        if ( network_device != null )
        {
            network_device.remove_all_networks();
            network_device.unregister();
            network_device = null;
            network = null;
        }
    }
}

// vim:ts=4:sw=4:expandtab
