/**
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

namespace FsoGsm {


public class AtDeviceGetFunctionality : DeviceGetFunctionality
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cfun = theModem.createAtCommand<PlusCFUN>( "+CFUN" );
        var response = yield theModem.processCommandAsync( cfun, cfun.query() );
        checkResponseValid( cfun, response );
        level = Constants.instance().deviceFunctionalityStatusToString( cfun.value );
        autoregister = theModem.data().keepRegistration;
        pin = theModem.data().simPin;
    }
}

public class AtDeviceGetInformation : DeviceGetInformation
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        info = new GLib.HashTable<string,Value?>( str_hash, str_equal );

        var value = Value( typeof(string) );

        var cgmr = theModem.createAtCommand<PlusCGMR>( "+CGMR" );
        var response = yield theModem.processCommandAsync( cgmr, cgmr.execute() );
        if ( cgmr.validate( response ) == Constants.AtResponse.VALID )
        {
            value = (string) cgmr.value;
            info.insert( "revision", value );
        }
        else
        {
            info.insert( "revision", "unknown" );
        }

        var cgmm = theModem.createAtCommand<PlusCGMM>( "+CGMM" );
        response = yield theModem.processCommandAsync( cgmm, cgmm.execute() );
        if ( cgmm.validate( response ) == Constants.AtResponse.VALID )
        {
            value = (string) cgmm.value;
            info.insert( "model", value );
        }
        else
        {
            info.insert( "model", "unknown" );
        }

        var cgmi = theModem.createAtCommand<PlusCGMI>( "+CGMI" );
        response = yield theModem.processCommandAsync( cgmi, cgmi.execute() );
        if ( cgmi.validate( response ) == Constants.AtResponse.VALID )
        {
            value = (string) cgmi.value;
            info.insert( "manufacturer", value );
        }
        else
        {
            info.insert( "manufacturer", "unknown" );
        }

        var cgsn = theModem.createAtCommand<PlusCGSN>( "+CGSN" );
        response = yield theModem.processCommandAsync( cgsn, cgsn.execute() );
        if ( cgsn.validate( response ) == Constants.AtResponse.VALID )
        {
            value = (string) cgsn.value;
            info.insert( "imei", value );
        }
        else
        {
            info.insert( "imei", "unknown" );
        }

        var cmickey = theModem.createAtCommand<PlusCMICKEY>( "+CMICKEY" );
        response = yield theModem.processCommandAsync( cmickey, cmickey.execute() );
        if ( cmickey.validate( response ) == Constants.AtResponse.VALID )
        {
            value = (string) cmickey.value;
            info.insert( "mickey", value );
        }
    }
}

public class AtDeviceGetPowerStatus : DeviceGetPowerStatus
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusCBC>( "+CBC" );
        var response = yield theModem.processCommandAsync( cmd, cmd.execute() );

        checkResponseValid( cmd, response );
        status = cmd.status;
        level = cmd.level;
    }
}

public class AtDeviceSetFunctionality : DeviceSetFunctionality
{
    public override async void run( string level, bool autoregister, string pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var value = Constants.instance().deviceFunctionalityStringToStatus( level );

        if ( value == -1 )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Functionality needs to be one of \"minimal\", \"airplane\", or \"full\"." );
        }

        var cmd = theModem.createAtCommand<PlusCFUN>( "+CFUN" );
        var response = yield theModem.processCommandAsync( cmd, cmd.issue( value ) );
        checkResponseExpected( cmd,
                         response,
                         { Constants.AtResponse.OK, Constants.AtResponse.CME_ERROR_011_SIM_PIN_REQUIRED } );
        var data = theModem.data();
        data.keepRegistration = autoregister;
        data.simPin = pin;

        yield gatherSimStatusAndUpdate();
    }
}

/**
 * SIM Mediators
 **/
public class AtSimGetAuthStatus : SimGetAuthStatus
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusCPIN>( "+CPIN" );
        var response = yield theModem.processCommandAsync( cmd, cmd.query() );
        checkResponseValid( cmd, response );
        status = cmd.status;
    }
}

public class AtSimGetInformation : SimGetInformation
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        info = new GLib.HashTable<string,Value?>( str_hash, str_equal );

        var value = Value( typeof(string) );

        var cimi = theModem.createAtCommand<PlusCGMR>( "+CIMI" );
        var response = yield theModem.processCommandAsync( cimi, cimi.execute() );
        if ( cimi.validate( response ) == Constants.AtResponse.VALID )
        {
            value = (string) cimi.value;
            info.insert( "imsi", value );
        }
        else
        {
            info.insert( "imsi", "unknown" );
        }

        var crsm = theModem.createAtCommand<PlusCRSM>( "+CRSM" );
        response = yield theModem.processCommandAsync( crsm, crsm.issue(
                Constants.SimFilesystemCommand.READ_BINARY,
                Constants.instance().simFilesystemEntryNameToCode( "EFspn" ), 0, 0, 17 ) );
        if ( crsm.validate( response ) == Constants.AtResponse.VALID )
        {
            var issuer = Codec.hexToString( crsm.payload );
            value = issuer != "" ? issuer : "unknown";
            info.insert( "issuer", value );
        }
        else
        {
            info.insert( "issuer", "unknown" );
        }

        //FIXME: Add dial_prefix and country
    }
}

public class AtSimGetAuthCodeRequired : SimGetAuthCodeRequired
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusCLCK>( "+CLCK" );
        var response = yield theModem.processCommandAsync( cmd, cmd.query( "SC" ) );
        checkResponseValid( cmd, response );
        required = cmd.enabled;
    }
}

public class AtSimSendAuthCode : SimSendAuthCode
{
    public override async void run( string pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusCPIN>( "+CPIN" );
        var response = yield theModem.processCommandAsync( cmd, cmd.issue( pin ) );
        checkResponseOk( cmd, response );
        gatherSimStatusAndUpdate();
    }
}


/**
 * SMS Mediators
 **/

/**
 * Network Mediators
 **/

public class AtNetworkRegister : NetworkRegister
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusCOPS>( "+COPS" );
        var response = yield theModem.processCommandAsync( cmd, cmd.issue( PlusCOPS.Action.REGISTER_WITH_BEST_PROVIDER ) );
        checkResponseOk( cmd, response );
    }
}

/**
 * Call Mediators
 **/
public class AtCallActivate : CallActivate
{
    public override async void run( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        yield theModem.callhandler.activate( id );
    }
}

public class AtCallHoldActive : CallHoldActive
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        yield theModem.callhandler.hold();
    }
}

public class AtCallInitiate : CallInitiate
{
    public override async void run( string number, string ctype ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        validatePhoneNumber( number );
        id = yield theModem.callhandler.initiate( number, ctype );
    }
}

public class AtCallListCalls : CallListCalls
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusCLCC>( "+CLCC" );
        var response = yield theModem.processCommandAsync( cmd, cmd.execute() );
        checkMultiResponseValid( cmd, response );
        calls = cmd.calls;
    }
}

public class AtCallSendDtmf : CallSendDtmf
{
    public override async void run( string tones ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusVTS>( "+VTS" );
        var response = yield theModem.processCommandAsync( cmd, cmd.issue( tones ) );
        checkResponseOk( cmd, response );
    }
}

public class AtCallRelease : CallRelease
{
    public override async void run( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        yield theModem.callhandler.release( id );
    }
}

public class AtCallReleaseAll : CallReleaseAll
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        yield theModem.callhandler.releaseAll();
    }
}

/**
 * PDP Mediators
 **/

/**
 * Register all mediators
 **/
public void registerMsmMediators( HashMap<Type,Type> table )
{
    table[ typeof(DeviceGetAlarmTime) ]           = typeof( AtDeviceGetAlarmTime );
    table[ typeof(DeviceGetAntennaPower) ]        = typeof( AtDeviceGetAntennaPower );
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
    table[ typeof(DeviceSetSimBuffersSms) ]       = typeof( AtDeviceSetSimBuffersSms );
    table[ typeof(DeviceSetSpeakerVolume) ]       = typeof( AtDeviceSetSpeakerVolume );

    table[ typeof(SimChangeAuthCode) ]            = typeof( AtSimChangeAuthCode );
    table[ typeof(SimGetAuthCodeRequired) ]       = typeof( AtSimGetAuthCodeRequired );
    table[ typeof(SimGetAuthStatus) ]             = typeof( AtSimGetAuthStatus );
    table[ typeof(SimGetServiceCenterNumber) ]    = typeof( AtSimGetServiceCenterNumber );
    table[ typeof(SimGetInformation) ]            = typeof( AtSimGetInformation );
    table[ typeof(SimListPhonebooks) ]            = typeof( AtSimListPhonebooks );
    table[ typeof(SimRetrieveMessagebook) ]       = typeof( AtSimRetrieveMessagebook );
    table[ typeof(SimRetrievePhonebook) ]         = typeof( AtSimRetrievePhonebook );
    table[ typeof(SimSetAuthCodeRequired) ]       = typeof( AtSimSetAuthCodeRequired );
    table[ typeof(SimSendAuthCode) ]              = typeof( AtSimSendAuthCode );
    table[ typeof(SimSetServiceCenterNumber) ]    = typeof( AtSimSetServiceCenterNumber );
    table[ typeof(SimUnlock) ]                    = typeof( AtSimUnlock );

    table[ typeof(SmsGetSizeForMessage) ]         = typeof( AtSmsGetSizeForMessage );
    table[ typeof(SmsSendMessage) ]               = typeof( AtSmsSendMessage );

    table[ typeof(NetworkGetSignalStrength) ]     = typeof( AtNetworkGetSignalStrength );
    table[ typeof(NetworkGetStatus) ]             = typeof( AtNetworkGetStatus );
    table[ typeof(NetworkListProviders) ]         = typeof( AtNetworkListProviders );
    table[ typeof(NetworkRegister) ]              = typeof( AtNetworkRegister );

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
}

} // namespace FsoGsm
