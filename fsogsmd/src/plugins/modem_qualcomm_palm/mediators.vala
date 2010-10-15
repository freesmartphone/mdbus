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
 */

using Gee;
using FsoGsm;

/**
 * Public helpers
 **/
public void updateMsmSimAuthStatus( FreeSmartphone.GSM.SIMAuthStatus status )
{
    theModem.logger.info( @"SIM Auth status now $status" );
    
    // send the dbus signal
    var obj = theModem.theDevice<FreeSmartphone.GSM.SIM>();
    obj.auth_status( status );

    // check whether we need to advance the modem state
    var data = theModem.data();
    if ( status != data.simAuthStatus )
    {
        data.simAuthStatus = status;

        // advance global modem state
        var modemStatus = theModem.status();
        if ( modemStatus == Modem.Status.INITIALIZING )
        {
            if ( status == FreeSmartphone.GSM.SIMAuthStatus.READY )
            {
                theModem.advanceToState( Modem.Status.ALIVE_SIM_UNLOCKED );
            }
            else
            {
                theModem.advanceToState( Modem.Status.ALIVE_SIM_LOCKED );
            }
        }
    }
}

/**
 * Register all mediators
 **/
public void registerMsmMediators( HashMap<Type,Type> table )
{
    table[ typeof(DebugPing) ]                    = typeof( MsmDebugPing );

    table[ typeof(DeviceGetFeatures) ]            = typeof( MsmDeviceGetFeatures );
    table[ typeof(DeviceGetInformation) ]         = typeof( MsmDeviceGetInformation );
    table[ typeof(DeviceGetFunctionality) ]       = typeof( MsmDeviceGetFunctionality );
    table[ typeof(DeviceGetPowerStatus) ]         = typeof( MsmDeviceGetPowerStatus );
    table[ typeof(DeviceSetFunctionality) ]       = typeof( MsmDeviceSetFunctionality );

    table[ typeof(SimGetAuthCodeRequired) ]       = typeof( MsmSimGetAuthCodeRequired );
    table[ typeof(SimGetAuthStatus) ]             = typeof( MsmSimGetAuthStatus );
    table[ typeof(SimGetInformation) ]            = typeof( MsmSimGetInformation );
    table[ typeof(SimSendAuthCode) ]              = typeof( MsmSimSendAuthCode );
    table[ typeof(SimDeleteEntry) ]               = typeof( MsmSimDeleteEntry );
    table[ typeof(SimDeleteMessage) ]             = typeof( MsmSimDeleteMessage );
    table[ typeof(SimGetPhonebookInfo) ]          = typeof( MsmSimGetPhonebookInfo );
    table[ typeof(SimGetServiceCenterNumber) ]    = typeof( MsmSimGetServiceCenterNumber );
    table[ typeof(SimGetUnlockCounters) ]         = typeof( MsmSimGetUnlockCounters );
    table[ typeof(SimRetrieveMessage) ]           = typeof( MsmSimRetrieveMessage );
    table[ typeof(SimRetrievePhonebook) ]         = typeof( MsmSimRetrievePhonebook );
    table[ typeof(SimSendStoredMessage) ]         = typeof( MsmSimSendStoredMessage );
    table[ typeof(SimSetServiceCenterNumber) ]    = typeof( MsmSimSetServiceCenterNumber );
    table[ typeof(SimStoreMessage) ]              = typeof( MsmSimStoreMessage );
    table[ typeof(SimWriteEntry) ]                = typeof( MsmSimWriteEntry );

    table[ typeof(NetworkRegister) ]              = typeof( MsmNetworkRegister );
    table[ typeof(NetworkUnregister) ]            = typeof( MsmNetworkUnregister );
    table[ typeof(NetworkGetSignalStrength) ]     = typeof( MsmNetworkGetSignalStrength );
    table[ typeof(NetworkGetStatus) ]             = typeof( MsmNetworkGetStatus );
    table[ typeof(NetworkListProviders) ]         = typeof( MsmNetworkListProviders );
    table[ typeof(NetworkGetCallingId) ]          = typeof( MsmNetworkGetCallingId );
    table[ typeof(NetworkSendUssdRequest) ]       = typeof( MsmNetworkSendUssdRequest );

    table[ typeof(CallActivate) ]                 = typeof( MsmCallActivate );
    table[ typeof(CallHoldActive) ]               = typeof( MsmCallHoldActive );
    table[ typeof(CallInitiate) ]                 = typeof( MsmCallInitiate );
    table[ typeof(CallListCalls) ]                = typeof( MsmCallListCalls );
    table[ typeof(CallReleaseAll) ]               = typeof( MsmCallReleaseAll );
    table[ typeof(CallRelease) ]                  = typeof( MsmCallRelease );
    table[ typeof(CallSendDtmf) ]                 = typeof( MsmCallSendDtmf );
}
