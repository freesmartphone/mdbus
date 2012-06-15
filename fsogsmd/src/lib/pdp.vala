/*
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

/**
 * @class RouteInfo
 **/
public class FsoGsm.RouteInfo
{
    public string iface;
    public string ipv4addr;
    public string ipv4mask;
    public string ipv4gateway;
    public string dns1;
    public string dns2;
}

/**
 * @interface PdpHandler
 **/
public interface FsoGsm.IPdpHandler : FsoFramework.AbstractObject
{
    public abstract FreeSmartphone.GSM.ContextStatus status { get; set; }
    public abstract GLib.HashTable<string,Variant> properties { get; set; }

    public async abstract void activate() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
    public async abstract void deactivate() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;

    public async abstract void statusUpdate( string status, GLib.HashTable<string,Variant> properties );

    public async abstract void connectedWithNewDefaultRoute( FsoGsm.RouteInfo route );

    public abstract void disconnected();

    public abstract async void syncStatus();

    public abstract void assign_modem( FsoGsm.Modem modem );
}

/**
 * @class NullPdpHandler
 **/
public class FsoGsm.NullPdpHandler : IPdpHandler, FsoFramework.AbstractObject
{
    public FreeSmartphone.GSM.ContextStatus status { get; set; default = FreeSmartphone.GSM.ContextStatus.RELEASED; }
    public GLib.HashTable<string,Variant> properties { get; set; default = new GLib.HashTable<string,Variant>( null, null ); }

    public async void activate() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }

    public async void deactivate() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }

    public async void statusUpdate( string status, GLib.HashTable<string,Variant> properties )
    {
    }

    public async void connectedWithNewDefaultRoute( FsoGsm.RouteInfo route )
    {
    }

    public void disconnected()
    {
    }

    public async void syncStatus()
    {
    }

    public void assign_modem(  FsoGsm.Modem modem )
    {
    }

    public override string repr()
    {
        return @"<>";
    }
}

/**
 * @class PdpHandler
 **/
public abstract class FsoGsm.PdpHandler : IPdpHandler, FsoFramework.AbstractObject
{
    private string lastNetworkRegistrationStatus = "unknown";
    private bool inSyncStatus = false;

    protected FsoGsm.Modem modem { get; private set; }

    public FreeSmartphone.GSM.ContextStatus status { get; set; }
    public GLib.HashTable<string,Variant> properties { get; set; }

    construct
    {
        status = FreeSmartphone.GSM.ContextStatus.RELEASED;
        properties = new GLib.HashTable<string,Variant>( str_hash, str_equal );

        // defer registration for network status updates a little bit as modem device is
        // not ready at this time (currently it's modem construction time).
        Idle.add( () => {
            var network = modem.theDevice<FreeSmartphone.GSM.Network>();
            network.status.connect( ( status ) => { syncStatus(); } );
            var device = modem.theDevice<FreeSmartphone.GSM.Device>();
            device.device_status.connect( ( status ) => { syncStatus(); } );
            return false;
        } );
    }

    public void assign_modem( FsoGsm.Modem modem )
    {
        this.modem = modem;
    }

    //
    // protected API
    //

    protected async virtual void sc_activate() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }

    protected async virtual void sc_deactivate() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }

    protected async void updateStatus( FreeSmartphone.GSM.ContextStatus status, GLib.HashTable<string,Variant> properties )
    {
        if ( status == this.status )
        {
            return;
        }

        logger.info( @"PDP Context Status now $status" );
        this.status = status;
        this.properties = properties;

        var obj = modem.theDevice<FreeSmartphone.GSM.PDP>();
        obj.context_status( status, properties );
    }

    //
    // public API
    //

    public async void activate() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        if ( this.status != FreeSmartphone.GSM.ContextStatus.RELEASED )
        {
            throw new FreeSmartphone.Error.UNAVAILABLE( @"Can't activate context while in status $status" );
        }

        var status = new GLib.HashTable<string,Variant>( GLib.str_hash, GLib.str_equal );
        updateStatus( FreeSmartphone.GSM.ContextStatus.OUTGOING, status );

        try
        {
            yield sc_activate();
        }
        catch ( FreeSmartphone.GSM.Error e1 )
        {
            updateStatus( FreeSmartphone.GSM.ContextStatus.RELEASED, status );
            throw e1;
        }
        catch ( FreeSmartphone.Error e2 )
        {
            updateStatus( FreeSmartphone.GSM.ContextStatus.RELEASED, status );
            throw e2;
        }
    }

    public async void deactivate() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        if ( this.status != FreeSmartphone.GSM.ContextStatus.ACTIVE &&
             this.status != FreeSmartphone.GSM.ContextStatus.SUSPENDED )
        {
            throw new FreeSmartphone.Error.UNAVAILABLE( @"Can't deactivate context while in status $status" );
        }

        yield sc_deactivate();

        var status = new GLib.HashTable<string,Variant>( GLib.str_hash, GLib.str_equal );
        updateStatus( FreeSmartphone.GSM.ContextStatus.RELEASED, status );
    }

    public async abstract void statusUpdate( string status, GLib.HashTable<string,Variant> properties );

    public async void connectedWithNewDefaultRoute( FsoGsm.RouteInfo route )
    {
        try
        {
            new FsoFramework.Network.Interface( route.iface ).up();
        }
        catch ( FsoFramework.Network.Error err )
        {
            logger.error( @"Could not activate network interface $(route.iface); " +
                           "still setting context status to ACTIVE" );
        }

        var status = new GLib.HashTable<string,Variant>( GLib.str_hash, GLib.str_equal );
        status.insert( "ipv4addr", route.ipv4addr );
        status.insert( "ipv4mask", route.ipv4mask );
        status.insert( "ipv4gateway", route.ipv4gateway );
        status.insert( "dns1", route.dns1 );
        status.insert( "dns2", route.dns2 );

        updateStatus( FreeSmartphone.GSM.ContextStatus.ACTIVE, status );

        var setupNetworkRoute = FsoFramework.theConfig.boolValue( "fsogsm", "pdp_setup_network_route", true );
        if ( setupNetworkRoute )
        {
            try
            {
                // FIXME: change to async
                var network = Bus.get_proxy_sync<FreeSmartphone.Network>( BusType.SYSTEM, FsoFramework.Network.ServiceDBusName,
                    FsoFramework.Network.ServicePathPrefix );

                yield network.offer_default_route( "cellular", route.iface, route.ipv4addr, route.ipv4mask,
                    route.ipv4gateway, route.dns1, route.dns2 );
            }
            catch ( GLib.Error e )
            {
                logger.error( @"Can't call offer_default_route on onetworkd: $(e.message)" );
            }
        }
    }

    public void disconnected()
    {
        var status = new GLib.HashTable<string,Variant>( GLib.str_hash, GLib.str_equal );
        updateStatus( FreeSmartphone.GSM.ContextStatus.RELEASED, status );
    }

    public async void syncStatus()
    {
        if ( inSyncStatus )
            return;

        inSyncStatus = true;

        var networkRegistrationStatus = lastNetworkRegistrationStatus;
        var roamingAllowed = modem.data().roamingAllowed;
        var nextContextStatus = status;

        if ( !modem.isAlive() || this.status == FreeSmartphone.GSM.ContextStatus.RELEASED )
            return;

        try
        {
            var network = modem.theDevice<FreeSmartphone.GSM.Network>();
            var networkStatus = yield network.get_status();

            if ( ( networkRegistrationStatus = (string) networkStatus.lookup( "pdp.registration" ) ) == null &&
                 ( networkRegistrationStatus = (string) networkStatus.lookup( "registration" ) ) == null )
                 networkRegistrationStatus = lastNetworkRegistrationStatus;

            var registered = ( networkRegistrationStatus == "registered" );

            if ( registered || ( roamingAllowed && networkRegistrationStatus == "roaming" ) )
            {
                nextContextStatus = FreeSmartphone.GSM.ContextStatus.ACTIVE;
            }
            else if ( networkRegistrationStatus != "home" && networkRegistrationStatus != "roaming" )
            {
                nextContextStatus = FreeSmartphone.GSM.ContextStatus.SUSPENDED;
            }

            if ( nextContextStatus != status )
            {
                switch ( nextContextStatus )
                {
                    case FreeSmartphone.GSM.ContextStatus.ACTIVE:
                        activate();
                        break;
                    case FreeSmartphone.GSM.ContextStatus.RELEASED:
                        deactivate();
                        break;
                    case FreeSmartphone.GSM.ContextStatus.SUSPENDED:
                        updateStatus( nextContextStatus, this.properties );
                        break;
                }
            }

            lastNetworkRegistrationStatus = networkRegistrationStatus;
        }
        catch ( GLib.Error e )
        {
            logger.error( @"Could not synchronize PDP registration status" );
        }

        inSyncStatus = false;
    }
}

// vim:ts=4:sw=4:expandtab
