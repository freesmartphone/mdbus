/*
 * Copyright (C) 2010-2011 Simon Busch <morphis@gravedo.de>
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

private string networkRegistrationStatusToString( Msmcomm.NetworkRegistrationStatus reg_status )
{
    string result = "unknown";

    switch ( reg_status )
    {
        case Msmcomm.NetworkRegistrationStatus.NO_SERVICE:
            result = "unregistered";
            break;
        case Msmcomm.NetworkRegistrationStatus.HOME:
            result = "home";
            break;
        case Msmcomm.NetworkRegistrationStatus.ROAMING:
            result = "roaming";
            break;
        case Msmcomm.NetworkRegistrationStatus.DENIED:
            result = "denied";
            break;
        case Msmcomm.NetworkRegistrationStatus.SEARCHING:
            result = "busy";
            break;
    }

    return result;
}

public async void changeOperationMode( Msmcomm.OperationMode operation_mode ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
{
    var channel = theModem.channel( "main" ) as MsmChannel;

    if ( MsmData.operation_mode == operation_mode )
    {
        return;
    }

    try
    {
        yield channel.state_service.change_operation_mode( operation_mode );
        MsmData.operation_mode = operation_mode;
    }
    catch ( Msmcomm.Error err0 )
    {
        handleMsmcommErrorMessage( err0 );
    }
    catch ( Error err1 )
    {
    }
}

public void fillNetworkStatusInfo(GLib.HashTable<string,Variant> status)
{
    status.insert( "strength", MsmData.network_info.rssi );
    status.insert( "provider", MsmData.network_info.operator_name );
    status.insert( "network", MsmData.network_info.operator_name );
    status.insert( "display", MsmData.network_info.operator_name );
    status.insert( "registration", networkRegistrationStatusToString( MsmData.network_info.reg_status ) );
    status.insert( "mode", "automatic" );
    status.insert( "lac", "" );
    status.insert( "cid", "" );
    status.insert( "act", "GSM" );
}

public class MsmNetworkRegister : NetworkRegister
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        yield changeOperationMode( Msmcomm.OperationMode.ONLINE );
    }
}

public class MsmNetworkUnregister : NetworkUnregister
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        yield changeOperationMode( Msmcomm.OperationMode.OFFLINE );

        // After we switched to offline mode now we have to resend the pin to the modem to
        // authenticate again
        if ( theModem.data().simPin.length > 0 )
        {
            var m = theModem.createMediator<FsoGsm.SimSendAuthCode>();
            yield m.run( theModem.data().simPin );
        }
        else
        {
            updateMsmSimAuthStatus( FreeSmartphone.GSM.SIMAuthStatus.PIN_REQUIRED );
        }
    }
}
public class MsmNetworkGetSignalStrength : NetworkGetSignalStrength
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        signal = (int) MsmData.network_info.rssi;
    }
}

public class MsmNetworkGetStatus : NetworkGetStatus
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        status = new GLib.HashTable<string, Variant>( str_hash, str_equal );

        if ( MsmData.operation_mode == Msmcomm.OperationMode.ONLINE )
        {
            fillNetworkStatusInfo( status );
        }
        else
        {
            status.insert( "registration", "unregistered" );
        }
    }
}

public class MsmNetworkListProviders : NetworkListProviders
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.UNSUPPORTED( "Not yet implemented" );
    }
}

public class MsmNetworkSendUssdRequest : NetworkSendUssdRequest
{
    public override async void run( string request ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.UNSUPPORTED( "Not yet implemented" );
    }
}

public class MsmNetworkGetCallingId : NetworkGetCallingId
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.UNSUPPORTED( "Not yet implemented" );
    }
}

public class MsmNetworkSetCallingId : NetworkSetCallingId
{
    public override async void run( FreeSmartphone.GSM.CallingIdentificationStatus status ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.UNSUPPORTED( "Not yet implemented" );
    }
}


