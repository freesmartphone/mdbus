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
    public async abstract void activate() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
    public async abstract void deactivate() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;

    public async abstract void statusUpdate( string status, GLib.HashTable<string,Variant> properties );

    public async abstract void connectedWithNewDefaultRoute( FsoGsm.RouteInfo route );

    public abstract void disconnected();
}

/**
 * @class PdpHandler
 **/
public abstract class FsoGsm.PdpHandler : IPdpHandler, FsoFramework.AbstractObject
{
    private string lastNetworkRegistrationStatus = "unknown";

    public FreeSmartphone.GSM.ContextStatus status { get; set; }
    public GLib.HashTable<string,Variant> properties { get; set; }

    construct
    {
        status = FreeSmartphone.GSM.ContextStatus.RELEASED;
        properties = new GLib.HashTable<string,Variant>( str_hash, str_equal );
        var network = theModem.theDevice<FreeSmartphone.GSM.Network>();
        network.status.connect( ( status ) => { syncStatus(); } );
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

        var obj = theModem.theDevice<FreeSmartphone.GSM.PDP>();
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
        if ( this.status != FreeSmartphone.GSM.ContextStatus.ACTIVE )
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
        updateStatus( FreeSmartphone.GSM.ContextStatus.ACTIVE, status );

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

    public void disconnected()
    {
        var status = new GLib.HashTable<string,Variant>( GLib.str_hash, GLib.str_equal );
        updateStatus( FreeSmartphone.GSM.ContextStatus.RELEASED, new GLib.HashTable<string,Variant>( GLib.str_hash, GLib.str_equal ) );
    }

    public async void syncStatus()
    {
        var networkRegistrationStatus = "unknown";
        var roamingAllowed = theModem.data().roamingAllowed;

        var network = theModem.theDevice<FreeSmartphone.GSM.Network>();
        var networkStatus = yield network.get_status();

        if ( networkStatus.lookup( "registration" ) != null )
            networkRegistrationStatus = lastNetworkRegistrationStatus;

        // FIXME maybe we should add a flag like reconnectAuto to let the context be
        // reactivated automatically whenever roamingAllowed or networkStatus changed
        // again.
        if ( this.status == FreeSmartphone.GSM.ContextStatus.RELEASED )
            return;

        var registered = ( networkRegistrationStatus == "registered" );
        var nextContextStatus = status;

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
}

// vim:ts=4:sw=4:expandtab
