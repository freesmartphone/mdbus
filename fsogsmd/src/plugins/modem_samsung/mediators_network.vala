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
        var channel = theModem.channel( "main" ) as Samsung.IpcChannel;
        SamsungIpc.Response? response = null;

        // register with default network by setting PLMN selection to automatic
        var req = SamsungIpc.Network.PlmnSelectionSetMessage();
        req.setup( SamsungIpc.Network.PlmnSelectionMode.AUTO, null, SamsungIpc.Network.AccessTechnology.UMTS );
        response = yield channel.enqueue_async( SamsungIpc.RequestType.SET, SamsungIpc.MessageType.NET_PLMN_SEL, req.data );
        if ( response == null )
            throw new FreeSmartphone.Error.INTERNAL_ERROR( "Could set network selection mode!" );
    }
}

public class SamsungNetworkRegisterWithProvider : NetworkRegisterWithProvider
{
    public override async void run( string operator_code ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var channel = theModem.channel( "main" ) as Samsung.IpcChannel;
        var succeeded = false;
        SamsungIpc.Response? response = null;

        if ( operator_code.length != 5 )
            throw new FreeSmartphone.Error.INVALID_PARAMETER( @"Got invalid operator code: $(operator_code)" );

        var req = SamsungIpc.Network.PlmnSelectionSetMessage();
        req.setup( SamsungIpc.Network.PlmnSelectionMode.MANUAL, operator_code, SamsungIpc.Network.AccessTechnology.UMTS );

        response = yield channel.enqueue_async( SamsungIpc.RequestType.SET, SamsungIpc.MessageType.NET_PLMN_SEL, req.data );
        if ( response != null )
        {
            var genresp = (SamsungIpc.Generic.PhoneResponseMessage*) response;
            succeeded = ( genresp.code == 0x80 );
        }

        if ( !succeeded )
            throw new FreeSmartphone.Error.INTERNAL_ERROR( @"Could not register with network $(operator_code)" );
    }
}

public class SamsungNetworkUnregister : NetworkUnregister
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.UNSUPPORTED( @"Unregistering from a network is unsupported with this modem type!" );
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

        // use cached SIM provider name as they are read from modem whenever the SIM card
        // is exchanged and are not changing while operating with the same card
        if (Samsung.ModemState.sim_provider_name != null)
        {
            status.insert( "provider", Samsung.ModemState.sim_provider_name );
            status.insert( "display", Samsung.ModemState.sim_provider_name );
        }

        // query signal strength from modem
        var m = theModem.createMediator<NetworkGetSignalStrength>();
        yield m.run();
        status.insert( "strength", m.signal );

        // query telephony registration status
        var req = SamsungIpc.Network.RegistrationGetMessage();
        req.setup( SamsungIpc.Network.ServiceDomain.GSM );
        response = yield channel.enqueue_async( SamsungIpc.RequestType.GET, SamsungIpc.MessageType.NET_REGIST, req.data );

        if ( response == null )
            throw new FreeSmartphone.Error.INTERNAL_ERROR( "Could not retrieve network status from modem" );

        SamsungIpc.Network.RegistrationMessage* reginfo = (SamsungIpc.Network.RegistrationMessage*) response.data;

        status.insert( "registration", networkRegistrationStateToString( reginfo.reg_state ) );
        status.insert( "mode", "automatic" );
        status.insert( "act", networkAccessTechnologyToString( reginfo.act ) );
        status.insert( "lac", @"$(reginfo.lac)" );
        status.insert( "cid", @"$(reginfo.cid)" );

        // query PDP registration status
        req = SamsungIpc.Network.RegistrationGetMessage();
        req.setup( SamsungIpc.Network.ServiceDomain.GSM );
        response = yield channel.enqueue_async( SamsungIpc.RequestType.GET, SamsungIpc.MessageType.NET_REGIST, req.data );

        if ( response == null )
            throw new FreeSmartphone.Error.INTERNAL_ERROR( "Could not retrieve PDP network status from modem" );

        reginfo = (SamsungIpc.Network.RegistrationMessage*) response.data;

        status.insert( "pdp.registration", networkRegistrationStateToString( reginfo.reg_state ) );
        status.insert( "pdp.lac", @"$(reginfo.lac)" );
        status.insert( "pdp.cid", @"$(reginfo.cid)" );

        // query current network operator plmn
        response = yield channel.enqueue_async( SamsungIpc.RequestType.GET, SamsungIpc.MessageType.NET_CURRENT_PLMN );

        if ( response == null )
            throw new FreeSmartphone.Error.INTERNAL_ERROR( "Could not retrieve current network operator from modem" );

        var pr = (SamsungIpc.Network.CurrentPlmnMessage*) response.data;
        string plmn = "";
        for ( int n = 0; n < 5; n++)
            plmn += "%c".printf( pr.plmn[n] );

        if ( reginfo.reg_state == SamsungIpc.Network.RegistrationState.HOME  ||
             reginfo.reg_state == SamsungIpc.Network.RegistrationState.ROAMING )
        {
            status.insert( "code", plmn );
        }
    }
}

public class SamsungNetworkListProviders : NetworkListProviders
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        unowned SamsungIpc.Response? response;
        var channel = theModem.channel( "main" ) as Samsung.IpcChannel;
        FreeSmartphone.GSM.NetworkProvider[] _providers = { };

        response = yield channel.enqueue_async( SamsungIpc.RequestType.GET, SamsungIpc.MessageType.NET_PLMN_LIST, new uint8[] { }, 0, -1 );
        if ( response == null )
            throw new FreeSmartphone.Error.INTERNAL_ERROR( "Could not retrieve current network providers from modem!" );

        var pr = (SamsungIpc.Network.PlmnEntriesMessage*) response.data;
        for ( var n = 0; n < pr.num; n++ )
        {
            unowned SamsungIpc.Network.PlmnEntryMessage? currentNetwork = pr.get_entry( response, n );
            var mccmnc = "";

            for ( int m = 0; m < 5; m++ )
                mccmnc += "%c".printf( currentNetwork.plmn[m] );

            // FIXME whats with currentNetwork.type?

            var providerInfo = findProviderForMccMnc( mccmnc );

            var p = FreeSmartphone.GSM.NetworkProvider(
                Constants.instance().networkProviderStatusToString( (int) currentNetwork.status - 1 ),
                providerInfo.name, providerInfo.name, mccmnc, "");

            _providers += p;
        }

        providers = _providers;
    }
}

// vim:ts=4:sw=4:expandtab
