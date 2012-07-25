/*
 * Copyright (C) 2009-2012 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

/**
 * This file contains Dbus/AT command mediators only using official 3GPP AT commands.
 *
 * Do _not_ add vendor-specific mediators here, instead add them to your modem plugin.
 **/

using Gee;

namespace FsoGsm {

static bool inGatherSimStatusAndUpdate;

/**
 * Parsing and response checking helpers
 **/
internal void throwAppropriateError( Constants.AtResponse code, string detail ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
{
    var error = Constants.atResponseCodeToError( code, detail );
    throw error;
}

/**
 * Throws an error if response is not OK
 **/
public void checkResponseOk( FsoGsm.AtCommand command, string[] response ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
{
    var code = command.validateOk( response );
    if ( code == Constants.AtResponse.OK )
    {
        return;
    }
    else
    {
        throwAppropriateError( code, response[response.length-1] );
    }
}

/**
 * Throws an error if response is not among the list of expected responses.
 *
 * @returns the (expected) AT error code
 **/
public Constants.AtResponse checkResponseExpected( FsoGsm.AtCommand command,
                                     string[] response,
                                     Constants.AtResponse[] expected
                                   ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
{
    var code = command.validateOk( response );

    for ( int i = 0; i < expected.length; ++i )
    {
        if ( code == expected[i] )
        {
            return code;
        }
    }

    throwAppropriateError( code, response[response.length-1] );

    assert_not_reached(); // if this fails here, then our code is broken
}

public void checkResponseConnect( FsoGsm.AtCommand command, string[] response ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
{
    var code = command.validateOk( response );
    if ( code == Constants.AtResponse.CONNECT )
    {
        return;
    }
    else
    {
        throwAppropriateError( code, response[response.length-1] );
    }
}

public void checkTestResponseValid( FsoGsm.AtCommand command, string[] response ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
{
    var code = command.validateTest( response );
    if ( code == Constants.AtResponse.VALID )
    {
        return;
    }
    else
    {
        throwAppropriateError( code, response[response.length-1] );
    }
}

public void checkResponseValid( FsoGsm.AtCommand command, string[] response ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
{
    var code = command.validate( response );
    if ( code == Constants.AtResponse.VALID )
    {
        return;
    }
    else
    {
        throwAppropriateError( code, response[response.length-1] );
    }
}

public void checkMultiResponseValid( FsoGsm.AtCommand command, string[] response ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
{
    var code = command.validateMulti( response );
    if ( code == Constants.AtResponse.VALID )
    {
        return;
    }
    else
    {
        throwAppropriateError( code, response[response.length-1] );
    }
}

/**
 * Modem facilities helpers
 **/
public async void gatherSimOperators( FsoGsm.Modem modem ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
{
    /*
    var data = modem.data();
    if ( data.simOperatorbook == null );
    {
        var copn = modem.createAtCommand<PlusCOPN>( "+COPN" );
        var response = yield modem.processAtCommandAsync( copn, copn.execute() );
        if ( copn.validateMulti( response ) == Constants.AtResponse.VALID )
        {
            data.simOperatorbook = copn.operators;
        }
        else
        {
            data.simOperatorbook = new GLib.HashTable<string,string>( GLib.str_hash, GLib.str_equal );
        }
    }
    */
}

public async void gatherSpeakerVolumeRange( FsoGsm.Modem modem ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
{
    var data = modem.data();
    if ( data.speakerVolumeMinimum == -1 )
    {
        var clvl = modem.createAtCommand<PlusCLVL>( "+CLVL" );
        var response = yield modem.processAtCommandAsync( clvl, clvl.test() );
        if ( clvl.validateTest( response ) == Constants.AtResponse.VALID )
        {
            data.speakerVolumeMinimum = clvl.min;
            data.speakerVolumeMaximum = clvl.max;
        }
        else
        {
            modem.logger.warning( "Modem does not support querying volume range. Assuming (0-255)" );
            data.speakerVolumeMinimum = 0;
            data.speakerVolumeMaximum = 255;
        }
    }
}

public async void gatherSimStatusAndUpdate( FsoGsm.Modem modem ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
{
    if ( inGatherSimStatusAndUpdate )
    {
        assert( modem.logger.debug( "already gathering sim status... ignoring additional trigger" ) );
        return;
    }
    inGatherSimStatusAndUpdate = true;

    yield gatherSimOperators( modem );

    var data = modem.data();

    var cmd = modem.createAtCommand<PlusCPIN>( "+CPIN" );
    var response = yield modem.processAtCommandAsync( cmd, cmd.query() );
    var rcode = cmd.validate( response );
    if ( rcode == Constants.AtResponse.VALID )
    {
        modem.logger.info( @"SIM Auth status $(cmd.status)" );
        // send the dbus signal
        var obj = modem.theDevice<FreeSmartphone.GSM.SIM>();
        obj.auth_status( cmd.status );

        // check whether we need to advance the modem state
        if ( cmd.status != data.simAuthStatus )
        {
            data.simAuthStatus = cmd.status;

            // advance global modem state
            var modemStatus = modem.status();
            if ( modemStatus >= Modem.Status.INITIALIZING && modemStatus <= Modem.Status.ALIVE_REGISTERED )
            {
                if ( cmd.status == FreeSmartphone.GSM.SIMAuthStatus.READY )
                {
                    modem.advanceToState( Modem.Status.ALIVE_SIM_UNLOCKED, true );
                }
                else
                {
                    modem.advanceToState( Modem.Status.ALIVE_SIM_LOCKED, true );
                }
            }
        }
    }
    else if ( rcode == Constants.AtResponse.CME_ERROR_010_SIM_NOT_INSERTED ||
              rcode == Constants.AtResponse.CME_ERROR_013_SIM_FAILURE )
    {
        modem.logger.info( "SIM not inserted or broken" );
        modem.advanceToState( Modem.Status.ALIVE_NO_SIM );
    }
    else
    {
        modem.logger.warning( "Unhandled error while querying SIM PIN status" );
    }

    inGatherSimStatusAndUpdate = false;
}

/**
 * Register all mediators
 **/
public void registerGenericAtMediators( HashMap<Type,Type> table )
{
    table[ typeof(DebugCommand) ]                 = typeof( AtDebugCommand );
    table[ typeof(DebugInjectResponse) ]          = typeof( AtDebugInjectResponse );
    table[ typeof(DebugPing) ]                    = typeof( AtDebugPing );

    table[ typeof(DeviceGetAlarmTime) ]           = typeof( AtDeviceGetAlarmTime );
    table[ typeof(DeviceGetCurrentTime) ]         = typeof( AtDeviceGetCurrentTime );
    table[ typeof(DeviceGetInformation) ]         = typeof( AtDeviceGetInformation );
    table[ typeof(DeviceGetFeatures) ]            = typeof( AtDeviceGetFeatures );
    table[ typeof(DeviceGetFunctionality) ]       = typeof( AtDeviceGetFunctionality );
    table[ typeof(DeviceGetMicrophoneMuted) ]     = typeof( AtDeviceGetMicrophoneMuted );
    table[ typeof(DeviceGetPowerStatus) ]         = typeof( AtDeviceGetPowerStatus );
    table[ typeof(DeviceGetSimBuffersSms) ]       = typeof( AtDeviceGetSimBuffersSms );
    table[ typeof(DeviceGetSpeakerVolume) ]       = typeof( AtDeviceGetSpeakerVolume );
    table[ typeof(DeviceSetAlarmTime) ]           = typeof( AtDeviceSetAlarmTime );
    table[ typeof(DeviceSetCurrentTime) ]         = typeof( AtDeviceSetCurrentTime );
    table[ typeof(DeviceSetFunctionality) ]       = typeof( AtDeviceSetFunctionality );
    table[ typeof(DeviceSetMicrophoneMuted) ]     = typeof( AtDeviceSetMicrophoneMuted );
    table[ typeof(DeviceSetSpeakerVolume) ]       = typeof( AtDeviceSetSpeakerVolume );

    table[ typeof(SimChangeAuthCode) ]            = typeof( AtSimChangeAuthCode );
    table[ typeof(SimDeleteEntry) ]               = typeof( AtSimDeleteEntry );
    table[ typeof(SimDeleteMessage) ]             = typeof( AtSimDeleteMessage );
    table[ typeof(SimGetAuthCodeRequired) ]       = typeof( AtSimGetAuthCodeRequired );
    table[ typeof(SimGetAuthStatus) ]             = typeof( AtSimGetAuthStatus );
    table[ typeof(SimGetServiceCenterNumber) ]    = typeof( AtSimGetServiceCenterNumber );
    table[ typeof(SimGetInformation) ]            = typeof( AtSimGetInformation );
    table[ typeof(SimGetPhonebookInfo) ]          = typeof( AtSimGetPhonebookInfo );
    table[ typeof(SimGetUnlockCounters) ]         = typeof( AtSimGetUnlockCounters );
    table[ typeof(SimRetrieveMessage) ]           = typeof( AtSimRetrieveMessage );
    table[ typeof(SimRetrievePhonebook) ]         = typeof( AtSimRetrievePhonebook );
    table[ typeof(SimSendAuthCode) ]              = typeof( AtSimSendAuthCode );
    table[ typeof(SimSendStoredMessage) ]         = typeof( AtSimSendStoredMessage );
    table[ typeof(SimSetAuthCodeRequired) ]       = typeof( AtSimSetAuthCodeRequired );
    table[ typeof(SimSetServiceCenterNumber) ]    = typeof( AtSimSetServiceCenterNumber );
    table[ typeof(SimStoreMessage) ]              = typeof( AtSimStoreMessage );
    table[ typeof(SimWriteEntry) ]                = typeof( AtSimWriteEntry );
    table[ typeof(SimUnlock) ]                    = typeof( AtSimUnlock );

    table[ typeof(SmsRetrieveTextMessages) ]      = typeof( AtSmsRetrieveTextMessages );
    table[ typeof(SmsGetSizeForTextMessage) ]     = typeof( AtSmsGetSizeForTextMessage );
    table[ typeof(SmsSendTextMessage) ]           = typeof( AtSmsSendTextMessage );

    table[ typeof(NetworkGetSignalStrength) ]     = typeof( AtNetworkGetSignalStrength );
    table[ typeof(NetworkGetStatus) ]             = typeof( AtNetworkGetStatus );
    table[ typeof(NetworkListProviders) ]         = typeof( AtNetworkListProviders );
    table[ typeof(NetworkRegister) ]              = typeof( AtNetworkRegister );
    table[ typeof(NetworkRegisterWithProvider) ]  = typeof( AtNetworkRegisterWithProvider );
    table[ typeof(NetworkUnregister) ]            = typeof( AtNetworkUnregister );
    table[ typeof(NetworkSendUssdRequest) ]       = typeof( AtNetworkSendUssdRequest );
    table[ typeof(NetworkGetCallingId) ]          = typeof( AtNetworkGetCallingId );
    table[ typeof(NetworkSetCallingId) ]          = typeof( AtNetworkSetCallingId );

    table[ typeof(CallActivate) ]                 = typeof( AtCallActivate );
    table[ typeof(CallHoldActive) ]               = typeof( AtCallHoldActive );
    table[ typeof(CallInitiate) ]                 = typeof( AtCallInitiate );
    table[ typeof(CallListCalls) ]                = typeof( AtCallListCalls );
    table[ typeof(CallReleaseAll) ]               = typeof( AtCallReleaseAll );
    table[ typeof(CallRelease) ]                  = typeof( AtCallRelease );
    table[ typeof(CallSendDtmf) ]                 = typeof( AtCallSendDtmf );
    table[ typeof(CallTransfer) ]                 = typeof( AtCallTransfer );
    table[ typeof(CallDeflect) ]                  = typeof( AtCallDeflect );
    table[ typeof(CallActivateConference) ]       = typeof( AtCallActivateConference );
    table[ typeof(CallJoin) ]                     = typeof( AtCallJoin );

    table[ typeof(CallForwardingEnable) ]         = typeof( AtCallForwardingEnable );
    table[ typeof(CallForwardingDisable) ]        = typeof( AtCallForwardingDisable );
    table[ typeof(CallForwardingQuery) ]          = typeof( AtCallForwardingQuery );

    table[ typeof(PdpActivateContext) ]           = typeof( AtPdpActivateContext );
    table[ typeof(PdpDeactivateContext) ]         = typeof( AtPdpDeactivateContext );
    table[ typeof(PdpSetCredentials) ]            = typeof( AtPdpSetCredentials );
    table[ typeof(PdpGetCredentials) ]            = typeof( AtPdpGetCredentials );

    table[ typeof(CbSetCellBroadcastSubscriptions) ] = typeof( AtCbSetCellBroadcastSubscriptions );
    table[ typeof(CbGetCellBroadcastSubscriptions) ] = typeof( AtCbGetCellBroadcastSubscriptions );

    table[ typeof(MonitorGetServingCellInformation) ] = typeof( AtMonitorGetServingCellInformation );
    table[ typeof(MonitorGetNeighbourCellInformation) ] = typeof( AtMonitorGetNeighbourCellInformation );

    table[ typeof(VoiceMailboxGetNumber) ]        = typeof( AtVoiceMailboxGetNumber );
    table[ typeof(VoiceMailboxSetNumber) ]        = typeof( AtVoiceMailboxSetNumber );
}

} // namespace FsoGsm

// vim:ts=4:sw=4:expandtab
