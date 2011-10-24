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
 */

using FsoGsm;
using Samsung;
using FsoFramework;

public class SamsungNetworkRegister : NetworkRegister
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        // FIXME how do we register to the network?
    }
}

public class SamsungNetworkUnregister : NetworkUnregister
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        // FIXME how do we unregister from the network?
    }
}
public class SamsungNetworkGetSignalStrength : NetworkGetSignalStrength
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        signal = Samsung.ModemState.network_signal_strength;
    }
}

public class SamsungNetworkGetStatus : NetworkGetStatus
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        unowned SamsungIpc.Response? response;
        var channel = theModem.channel( "main" ) as Samsung.IpcChannel;

        status = new GLib.HashTable<string, Variant>( str_hash, str_equal );

        // retrieve current network operator plmn
        response = yield channel.enqueue_async( SamsungIpc.RequestType.GET,
            SamsungIpc.MessageType.NET_CURRENT_PLMN, new uint8[] { } );

        if ( response == null )
            throw new FreeSmartphone.Error.INTERNAL_ERROR( "Could not retrieve current network operator from modem!" );

        var pr = (SamsungIpc.Network.CurrentPlmnMessage*) response.data;
        ModemState.network_plmn = "";
        for ( int n = 0; n < 5; n++)
            ModemState.network_plmn += "%c".printf( pr.plmn[n] );

        assert( theLogger.debug( @"current network plmn = $(ModemState.network_plmn)" ) );

        fillNetworkStatusInfo( status );
    }
}

// vim:ts=4:sw=4:expandtab
