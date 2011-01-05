/*
 * Copyright (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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


/**
 * Parsing and response checking helpers
 **/
internal void throwAppropriateError( Constants.AtResponse code, string detail ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
{
    var error = Constants.instance().atResponseCodeToError( code, detail );
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

internal void checkResponseConnect( FsoGsm.AtCommand command, string[] response ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
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

internal void checkTestResponseValid( FsoGsm.AtCommand command, string[] response ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
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

public void validatePhoneNumber( string number ) throws FreeSmartphone.Error
{
    if ( number == "" )
    {
        throw new FreeSmartphone.Error.INVALID_PARAMETER( "Number too short" );
    }

    for ( var i = ( number[0] == '+' ? 1 : 0 ); i < number.length; ++i )
    {
        if (number[i] >= '0' && number[i] <= '9')
                continue;

        if (number[i] == '*' || number[i] == '#')
                continue;

        throw new FreeSmartphone.Error.INVALID_PARAMETER( "Number contains invalid character '%c' at position %u", number[i], i );
    }
}

/**
 * Modem facilities helpers
 **/
public async void gatherSimOperators() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
{
    /*
    var data = theModem.data();
    if ( data.simOperatorbook == null );
    {
        var copn = theModem.createAtCommand<PlusCOPN>( "+COPN" );
        var response = yield theModem.processAtCommandAsync( copn, copn.execute() );
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

public async void gatherSpeakerVolumeRange() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
{
    var data = theModem.data();
    if ( data.speakerVolumeMinimum == -1 )
    {
        var clvl = theModem.createAtCommand<PlusCLVL>( "+CLVL" );
        var response = yield theModem.processAtCommandAsync( clvl, clvl.test() );
        if ( clvl.validateTest( response ) == Constants.AtResponse.VALID )
        {
            data.speakerVolumeMinimum = clvl.min;
            data.speakerVolumeMaximum = clvl.max;
        }
        else
        {
            theModem.logger.warning( "Modem does not support querying volume range. Assuming (0-255)" );
            data.speakerVolumeMinimum = 0;
            data.speakerVolumeMaximum = 255;
        }
    }
}

static bool inGatherSimStatusAndUpdate;
static bool inTriggerUpdateNetworkStatus;

public async void gatherSimStatusAndUpdate() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
{
    if ( inGatherSimStatusAndUpdate )
    {
        assert( theModem.logger.debug( "already gathering sim status... ignoring additional trigger" ) );
        return;
    }
    inGatherSimStatusAndUpdate = true;

    yield gatherSimOperators();

    var data = theModem.data();

    var cmd = theModem.createAtCommand<PlusCPIN>( "+CPIN" );
    var response = yield theModem.processAtCommandAsync( cmd, cmd.query() );
    var rcode = cmd.validate( response );
    if ( rcode == Constants.AtResponse.VALID )
    {
        theModem.logger.info( @"SIM Auth status $(cmd.status)" );
        // send the dbus signal
        var obj = theModem.theDevice<FreeSmartphone.GSM.SIM>();
        obj.auth_status( cmd.status );

        // check whether we need to advance the modem state
        if ( cmd.status != data.simAuthStatus )
        {
            data.simAuthStatus = cmd.status;

            // advance global modem state
            var modemStatus = theModem.status();
            if ( modemStatus >= Modem.Status.INITIALIZING && modemStatus <= Modem.Status.ALIVE_REGISTERED )
            {
                if ( cmd.status == FreeSmartphone.GSM.SIMAuthStatus.READY )
                {
                    theModem.advanceToState( Modem.Status.ALIVE_SIM_UNLOCKED, true );
                }
                else
                {
                    theModem.advanceToState( Modem.Status.ALIVE_SIM_LOCKED, true );
                }
            }
        }
    }
    else if ( rcode == Constants.AtResponse.CME_ERROR_010_SIM_NOT_INSERTED ||
              rcode == Constants.AtResponse.CME_ERROR_013_SIM_FAILURE )
    {
        theModem.logger.info( "SIM not inserted or broken" );
        theModem.advanceToState( Modem.Status.ALIVE_NO_SIM );
    }
    else
    {
        theModem.logger.warning( "Unhandled error while querying SIM PIN status" );
    }

    inGatherSimStatusAndUpdate = false;
}

public async void triggerUpdateNetworkStatus()
{
    if ( inTriggerUpdateNetworkStatus )
    {
        assert( theModem.logger.debug( "already gathering network status... ignoring additional trigger" ) );
        return;
    }
    inTriggerUpdateNetworkStatus = true;

    var mstat = theModem.status();

    // ignore, if we don't have proper status to issue networking commands yet
    if ( mstat != Modem.Status.ALIVE_SIM_READY && mstat != Modem.Status.ALIVE_REGISTERED )
    {
        assert( theModem.logger.debug( @"triggerUpdateNetworkStatus() ignored while modem is in status $mstat" ) );
        inTriggerUpdateNetworkStatus = false;
        return;
    }

    // gather info
    var m = theModem.createMediator<FsoGsm.NetworkGetStatus>();
    try
    {
        yield m.run();
    }
    catch ( GLib.Error e )
    {
        theModem.logger.warning( @"Can't query networking status: $(e.message)" );
        inTriggerUpdateNetworkStatus = false;
        return;
    }

    // advance modem status, if necessary
    var status = m.status.lookup( "registration" ).get_string();
    assert( theModem.logger.debug( @"triggerUpdateNetworkStatus() status = $status" ) );

    if ( status == "home" || status == "roaming" )
    {
        theModem.advanceToState( Modem.Status.ALIVE_REGISTERED );
    }
    else
    {
        theModem.advanceToState( Modem.Status.ALIVE_SIM_READY, true );
    }

    // send dbus signal
    var obj = theModem.theDevice<FreeSmartphone.GSM.Network>();
    obj.status( m.status );

    inTriggerUpdateNetworkStatus = false;
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
