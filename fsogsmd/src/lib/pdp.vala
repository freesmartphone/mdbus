/*
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
 **/

/**
 * @interface PdpHandler
 **/
public interface FsoGsm.IPdpHandler : FsoFramework.AbstractObject
{
    public async abstract void activate() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
    public async abstract void deactivate() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;

    public async abstract void statusUpdate( string status, GLib.HashTable<string,Variant> properties );

    public async abstract void connectedWithNewDefaultRoute( string iface, string ipv4addr, string ipv4mask, string ipv4gateway, string dns1, string dns2 );

    public abstract void disconnected();
}

/**
 * @class PdpHandler
 **/
public abstract class FsoGsm.PdpHandler : IPdpHandler, FsoFramework.AbstractObject
{
    public FreeSmartphone.GSM.ContextStatus status { get; set; }
    public GLib.HashTable<string,Variant> properties { get; set; }

    construct
    {
        status = FreeSmartphone.GSM.ContextStatus.RELEASED;
        properties = new GLib.HashTable<string,Variant>( str_hash, str_equal );
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

        updateStatus( FreeSmartphone.GSM.ContextStatus.OUTGOING, new GLib.HashTable<string,Variant>( GLib.str_hash, GLib.str_equal ) );

        try
        {
            yield sc_activate();
        }
        catch ( FreeSmartphone.GSM.Error e1 )
        {
            updateStatus( FreeSmartphone.GSM.ContextStatus.RELEASED, new GLib.HashTable<string,Variant>( GLib.str_hash, GLib.str_equal ) );
            throw e1;
        }
        catch ( FreeSmartphone.Error e2 )
        {
            updateStatus( FreeSmartphone.GSM.ContextStatus.RELEASED, new GLib.HashTable<string,Variant>( GLib.str_hash, GLib.str_equal ) );
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

        updateStatus( FreeSmartphone.GSM.ContextStatus.RELEASED, new GLib.HashTable<string,Variant>( GLib.str_hash, GLib.str_equal ) );
    }

    public async abstract void statusUpdate( string status, GLib.HashTable<string,Variant> properties );

    public async void connectedWithNewDefaultRoute( string iface, string ipv4addr, string ipv4mask, string ipv4gateway, string dns1, string dns2 )
    {
        updateStatus( FreeSmartphone.GSM.ContextStatus.ACTIVE, new GLib.HashTable<string,Variant>( GLib.str_hash, GLib.str_equal ) );

        try
        {
            // FIXME: change to async
            var network = Bus.get_proxy_sync<FreeSmartphone.Network>( BusType.SYSTEM, FsoFramework.Network.ServiceDBusName, FsoFramework.Network.ServicePathPrefix );
            yield network.offer_default_route( "cellular", iface, ipv4addr, ipv4mask, ipv4gateway, dns1, dns2 );
        }
        catch ( GLib.Error e )
        {
            logger.error( @"Can't call offer_default_route on onetworkd: $(e.message)" );
        }
    }

    // FIXME: reason?
    public void disconnected()
    {
        updateStatus( FreeSmartphone.GSM.ContextStatus.RELEASED, new GLib.HashTable<string,Variant>( GLib.str_hash, GLib.str_equal ) );
    }
}
