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
public abstract class FsoGsm.PdpHandler : FsoFramework.AbstractObject
{
    public async abstract void activate() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
    public async abstract void deactivate();

    public async abstract void statusUpdate( string status, GLib.HashTable<string,Value?> properties );

    public async void connectedWithNewDefaultRoute( string iface, string ipv4addr, string ipv4mask, string ipv4gateway, string dns1, string dns2 )
    {
        try
        {
            var conn = DBus.Bus.get( DBus.BusType.SYSTEM );
            FreeSmartphone.Network network = conn.get_object(
                FsoFramework.Network.ServiceDBusName,
                FsoFramework.Network.ServicePathPrefix,
                FsoFramework.Network.ServiceFacePrefix ) as FreeSmartphone.Network;

            yield network.offer_default_route( "cellular", iface, ipv4addr, ipv4mask, ipv4gateway, dns1, dns2 );
        }
        catch ( GLib.Error e )
        {
            logger.error( @"Can't call offer_default_route on onetworkd: $(e.message)" );
        }
    }
}
