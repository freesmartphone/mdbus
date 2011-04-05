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

public class FsoGsm.ModemHandler : FsoFramework.AbstractObject
{
    public struct Data
    {
        public string path;
        public Connman.Device? device;
        public bool available;
        public bool registered;
        public bool supports_gprs;
        public uint8 strength;
    }

    public Data data;

    private FreeSmartphone.Usage usage;
    private FreeSmartphone.GSM.SIM sim_service;
    private FreeSmartphone.GSM.PDP pdp_service;
    private FreeSmartphone.GSM.Device device_service;
    private FreeSmartphone.GSM.Network network_service;
    private bool initialized;

    private void reset_internal_data()
    {
        data = Data();
        data.path = "";
        data.available = false;
        data.registered = false;
        data.strength = 0;
        data.device = null;
    }

    private void on_resource_available( string name, bool availability )
    {
        if ( name == "GSM" )
        {
            if ( availability && !data.available )
            {
                on_gsm_resource_available();
            }
            else
            {
                data.available = false;
            }
        }
    }

    private T get_service<T>() throws GLib.Error
    {
        return Bus.get_proxy_sync<T>( BusType.SYSTEM, FsoFramework.GSM.ServiceDBusName,
                                      FsoFramework.GSM.DeviceServicePath, DBusProxyFlags.NONE );
    }

    private async void on_gsm_resource_available()
    {
        try
        {
            yield usage.request_resource( "GSM" );
            data.available = true;

            device_service = get_service<FreeSmartphone.GSM.Device>();
            sim_service = get_service<FreeSmartphone.GSM.SIM>();
            network_service = get_service<FreeSmartphone.GSM.Network>();
            pdp_service = get_service<FreeSmartphone.GSM.PDP>();

            logger.info( @"Successfully registered with GSM resource" );
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
                                                              GLib.DBusProxyFlags.NONE );
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

    public void shutdown()
    {
        logger.info( "Shuting down ..." );
    }
}

