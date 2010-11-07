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
 * Debug Mediators
 **/
public class AtDebugCommand : DebugCommand
{
    public override async void run( string command, string category ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = new CustomAtCommand( command );

        AtChannel channel = theModem.channel( category ) as AtChannel;
        //FIXME: assert channel is really an At channel
        if ( channel == null )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( @"Channel $category not known" );
        }

        var response = yield channel.enqueueAsync( cmd, command, 0 );
        var result = "";
        for ( int i = 0; i < response.length; ++i )
        {
            result += "\r\n";
            result += response[i];
        }
        this.response = result;
    }
}

public class AtDebugInjectResponse : DebugInjectResponse
{
    public override async void run( string command, string category ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var channel = theModem.channel( category );
        if ( channel == null )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( @"Channel $category not known" );
        }
        theModem.injectResponse( command, category );
    }
}

public class AtDebugPing : DebugPing
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<CustomAtCommand>( "CUSTOM" );

        AtChannel channel = theModem.channel( "main" ) as AtChannel;
        //FIXME: assert channel is really an At channel
        if ( channel == null )
        {
            throw new FreeSmartphone.Error.INTERNAL_ERROR( @"Main channel not found" );
        }

        var response = yield channel.enqueueAsync( cmd, "", 0 );
        checkResponseOk( cmd, response );
    }
}

/**
 * Device Mediators
 **/
public class AtDeviceGetAlarmTime : DeviceGetAlarmTime
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var data = theModem.data();
        var cmd = theModem.createAtCommand<PlusCALA>( "+CALA" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.query() );
        // org.freesmartphone.Device.RealtimeClock can not throw a org.freesmartphone.GSM.Error,
        // hence we need to catch this error and transform it into something valid
        try
        {
            checkResponseValid( cmd, response );
        }
        catch ( FreeSmartphone.GSM.Error e )
        {
            throw new FreeSmartphone.Error.SYSTEM_ERROR( e.message );
        }
        // some modems strip the leading zero for one-digit chars, so we have to reassemble it
        var timestr = "%02d/%02d/%02d,%02d:%02d:%02d".printf( cmd.year, cmd.month, cmd.day, cmd.hour, cmd.minute, cmd.second );
        var formatstr = "%y/%m/%d,%H:%M:%S";
        var t = GLib.Time();
        t.strptime( timestr, formatstr );
        since_epoch = (int) Linux.timegm( t );

        if ( since_epoch == data.alarmCleared )
        {
            since_epoch = 0;
        }
    }
}

public class AtDeviceGetCurrentTime : DeviceGetCurrentTime
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusCCLK>( "+CCLK" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.query() );
        // org.freesmartphone.Device.RealtimeClock can not throw a org.freesmartphone.GSM.Error,
        // hence we need to catch this error and transform it into something valid
        try
        {
            checkResponseValid( cmd, response );
        }
        catch ( FreeSmartphone.GSM.Error e )
        {
            throw new FreeSmartphone.Error.SYSTEM_ERROR( e.message );
        }
        // some modems strip the leading zero for one-digit chars, so we have to reassemble it
        var timestr = "%02d/%02d/%02d,%02d:%02d:%02d".printf( cmd.year, cmd.month, cmd.day, cmd.hour, cmd.minute, cmd.second );
        var formatstr = "%y/%m/%d,%H:%M:%S";
        var t = GLib.Time();
        t.strptime( timestr, formatstr );
        since_epoch = (int) Linux.timegm( t );
    }
}

public class AtDeviceGetFunctionality : DeviceGetFunctionality
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cfun = theModem.createAtCommand<PlusCFUN>( "+CFUN" );
        var response = yield theModem.processAtCommandAsync( cfun, cfun.query() );
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
        info = new GLib.HashTable<string,Variant>( str_hash, str_equal );

        Variant value;

        var cgmr = theModem.createAtCommand<PlusCGMR>( "+CGMR" );
        var response = yield theModem.processAtCommandAsync( cgmr, cgmr.execute() );
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
        response = yield theModem.processAtCommandAsync( cgmm, cgmm.execute() );
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
        response = yield theModem.processAtCommandAsync( cgmi, cgmi.execute() );
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
        response = yield theModem.processAtCommandAsync( cgsn, cgsn.execute() );
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
        response = yield theModem.processAtCommandAsync( cmickey, cmickey.execute() );
        if ( cmickey.validate( response ) == Constants.AtResponse.VALID )
        {
            value = (string) cmickey.value;
            info.insert( "mickey", value );
        }
    }
}

public class AtDeviceGetFeatures : DeviceGetFeatures
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        features = new GLib.HashTable<string,Variant>( str_hash, str_equal );

        // prefill results with what the modem claims
        var data = theModem.data();
        features.insert( "gsm", data.supportsGSM );
        features.insert( "voice", data.supportsVoice );
        features.insert( "cdma", data.supportsCDMA );
        features.insert( "csd", data.supportsCSD );
        features.insert( "fax", data.supportsFAX );

        // now some additional runtime checks

        // GSM?
        var gcap = theModem.createAtCommand<PlusGCAP>( "+GCAP" );
        var response = yield theModem.processAtCommandAsync( gcap, gcap.execute() );
        if ( gcap.validate( response ) == Constants.AtResponse.VALID )
        {
            if ( "GSM" in gcap.value || data.supportsGSM )
            {
                features.insert( "gsm", true );
            }
        }
        // PDP?
        var cgclass = theModem.createAtCommand<PlusCGCLASS>( "+CGCLASS" );
        response = yield theModem.processAtCommandAsync( cgclass, cgclass.test() );
        if ( cgclass.validateTest( response ) == Constants.AtResponse.VALID )
        {
            features.insert( "gprs", cgclass.righthandside );
        }
        // FAX?
        var fclass = theModem.createAtCommand<PlusFCLASS>( "+FCLASS" );
        response = yield theModem.processAtCommandAsync( fclass, fclass.test() );
        if ( fclass.validateTest( response ) == Constants.AtResponse.VALID )
        {
            features.insert( "fax", fclass.righthandside );
        }
        // facilities
        var fac = theModem.createAtCommand<PlusCLCK>( "+CLCK" );
        response = yield theModem.processAtCommandAsync( fac, fac.test() );
        if ( fac.validateTest( response ) == Constants.AtResponse.VALID )
        {
            features.insert( "facilities", fac.facilities );
        }
    }
}

public class AtDeviceGetMicrophoneMuted : DeviceGetMicrophoneMuted
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusCMUT>( "+CMUT" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.query() );
        checkResponseValid( cmd, response );
        muted = cmd.value == 1;
    }
}

public class AtDeviceGetSimBuffersSms : DeviceGetSimBuffersSms
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusCNMI>( "+CNMI" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.query() );
        checkResponseValid( cmd, response );
        buffers = cmd.mt < 2;
    }
}

public class AtDeviceGetSpeakerVolume : DeviceGetSpeakerVolume
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        yield gatherSpeakerVolumeRange();

        var cmd = theModem.createAtCommand<PlusCLVL>( "+CLVL" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.query() );
        checkResponseValid( cmd, response );

        var data = theModem.data();
        var interval = 100.0 / ( data.speakerVolumeMaximum - data.speakerVolumeMinimum );
        volume = data.speakerVolumeMinimum + (int) Math.round( cmd.value * interval );
    }
}

public class AtDeviceGetPowerStatus : DeviceGetPowerStatus
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusCBC>( "+CBC" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.execute() );
        checkResponseValid( cmd, response );

        switch ( cmd.status )
        {
            case PlusCBC.Status.DISCHARGING:
                if ( cmd.level > 20 )
                    status = FreeSmartphone.Device.PowerStatus.DISCHARGING;
                else if ( cmd.level > 10 )
                    status = FreeSmartphone.Device.PowerStatus.CRITICAL;
                else if ( cmd.level < 5 )
                    status = FreeSmartphone.Device.PowerStatus.EMPTY;
                break;
            case PlusCBC.Status.CHARGING:
                status = FreeSmartphone.Device.PowerStatus.CHARGING;
                break;
            case PlusCBC.Status.AC:
                status = FreeSmartphone.Device.PowerStatus.AC;
                break;
            default:
                status = FreeSmartphone.Device.PowerStatus.UNKNOWN;
                break;
        }
        level = cmd.level;
    }
}

public class AtDeviceSetAlarmTime : DeviceSetAlarmTime
{
    public override async void run( int since_epoch ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var t = GLib.Time.gm( (time_t) since_epoch );

        var cmd = theModem.createAtCommand<PlusCALA>( "+CALA" );
        var response = yield theModem.processAtCommandAsync( cmd, since_epoch > 0 ? cmd.issue( t.year+1900-2000, t.month+1, t.day, t.hour, t.minute, t.second, 0 ) : cmd.clear() );

        // org.freesmartphone.Device.RealtimeClock can not throw a org.freesmartphone.GSM.Error,
        // hence we need to catch this error and transform it into something valid
        try
        {
            checkResponseOk( cmd, response );
        }
        catch ( FreeSmartphone.GSM.Error e )
        {
            throw new FreeSmartphone.Error.SYSTEM_ERROR( e.message );
        }
    }
}

public class AtDeviceSetCurrentTime : DeviceSetCurrentTime
{
    public override async void run( int since_epoch ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var t = GLib.Time.gm( (time_t) since_epoch );

        var cmd = theModem.createAtCommand<PlusCCLK>( "+CCLK" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( t.year+1900-2000, t.month+1, t.day, t.hour, t.minute, t.second, 0 ) );

        // org.freesmartphone.Device.RealtimeClock can not throw a org.freesmartphone.GSM.Error,
        // hence we need to catch this error and transform it into something valid
        try
        {
            checkResponseOk( cmd, response );
        }
        catch ( FreeSmartphone.GSM.Error e )
        {
            throw new FreeSmartphone.Error.SYSTEM_ERROR( e.message );
        }
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
        var queryanswer = yield theModem.processAtCommandAsync( cmd, cmd.query() );
        checkResponseValid( cmd, queryanswer );
        var curlevel = Constants.instance().deviceFunctionalityStatusToString( cmd.value );
        if ( curlevel != level )
        {
            var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( value ) );
            checkResponseExpected( cmd,
                response,
                { Constants.AtResponse.OK, Constants.AtResponse.CME_ERROR_011_SIM_PIN_REQUIRED } );
        }
        var data = theModem.data();
        data.keepRegistration = autoregister;
        if ( pin != "" )
        {
            data.simPin = pin;
            theModem.watchdog.resetUnlockMarker();
        }
        yield gatherSimStatusAndUpdate();
    }
}

public class AtDeviceSetMicrophoneMuted : DeviceSetMicrophoneMuted
{
    public override async void run( bool muted ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmut = theModem.createAtCommand<PlusCMUT>( "+CMUT" );
        var response = yield theModem.processAtCommandAsync( cmut, cmut.issue( muted ? 1 : 0 ) );

        checkResponseOk( cmut, response );
    }
}

public class AtDeviceSetSpeakerVolume : DeviceSetSpeakerVolume
{
    public override async void run( int volume ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        if ( volume < 0 || volume > 100 )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Volume needs to be a percentage (0-100)" );
        }

        yield gatherSpeakerVolumeRange();

        var data = theModem.data();
        var interval = (double)( data.speakerVolumeMaximum - data.speakerVolumeMinimum ) / 100.0;
        var value = data.speakerVolumeMinimum + (int) Math.round( volume * interval );

        var clvl = theModem.createAtCommand<PlusCLVL>( "+CLVL" );
        var response = yield theModem.processAtCommandAsync( clvl, clvl.issue( value ) );
        checkResponseOk( clvl, response );
    }
}

/**
 * SIM Mediators
 **/
public class AtSimChangeAuthCode : SimChangeAuthCode
{
    public override async void run( string oldpin, string newpin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusCPWD>( "+CPWD" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( "SC", oldpin, newpin ) );
        checkResponseOk( cmd, response );
    }
}

public class AtSimDeleteEntry : SimDeleteEntry
{
    public override async void run( string category, int index ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cat = Constants.instance().simPhonebookStringToCode( category );
        if ( cat == "" )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Invalid category" );
        }

        var cmd = theModem.createAtCommand<PlusCPBW>( "+CPBW" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( cat, index ) );
        checkResponseExpected( cmd, response, {
            Constants.AtResponse.OK,
            Constants.AtResponse.CME_ERROR_021_INVALID_INDEX
        } );
        //FIXME: theModem.pbhandler.resync();
    }
}

public class AtSimDeleteMessage : SimDeleteMessage
{
    public override async void run( int index ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusCMGD>( "+CMGD" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( index ) );
        checkResponseExpected( cmd, response, {
            Constants.AtResponse.OK,
            Constants.AtResponse.CMS_ERROR_321_INVALID_MEMORY_INDEX
        } );
        //FIXME: theModem.smshandler.resync();
    }
}

public class AtSimGetAuthStatus : SimGetAuthStatus
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusCPIN>( "+CPIN" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.query() );
        checkResponseValid( cmd, response );
        status = cmd.status;
    }
}

public class AtSimGetAuthCodeRequired : SimGetAuthCodeRequired
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusCLCK>( "+CLCK" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.query( "SC" ) );
        checkResponseValid( cmd, response );
        required = cmd.enabled;
    }
}

public class AtSimGetInformation : SimGetInformation
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        info = new GLib.HashTable<string,Variant>( str_hash, str_equal );

        Variant value;

        var cimi = theModem.createAtCommand<PlusCGMR>( "+CIMI" );
        var response = yield theModem.processAtCommandAsync( cimi, cimi.execute() );
        if ( cimi.validate( response ) == Constants.AtResponse.VALID )
        {
            value = (string) cimi.value;
            info.insert( "imsi", value );
        }
        else
        {
            info.insert( "imsi", "unknown" );
        }

        /* SIM Issuer */
        value = "unknown";

        info.insert( "issuer", "unknown" );
        var crsm = theModem.createAtCommand<PlusCRSM>( "+CRSM" );
        response = yield theModem.processAtCommandAsync( crsm, crsm.issue(
                Constants.SimFilesystemCommand.READ_BINARY,
                Constants.instance().simFilesystemEntryNameToCode( "EFspn" ), 0, 0, 17 ) );
        if ( crsm.validate( response ) == Constants.AtResponse.VALID )
        {
            var issuer = Codec.hexToString( crsm.payload );
            value = issuer != "" ? issuer : "unknown";
            info.insert( "issuer", value );
        }

        if ( value.get_string() == "unknown" )
        {
            crsm = theModem.createAtCommand<PlusCRSM>( "+CRSM" );
            response = yield theModem.processAtCommandAsync( crsm, crsm.issue(
                Constants.SimFilesystemCommand.READ_BINARY,
                Constants.instance().simFilesystemEntryNameToCode( "EF_SPN_CPHS" ), 0, 0, 10 ) );
            if ( crsm.validate( response ) == Constants.AtResponse.VALID )
            {
                var issuer2 = Codec.hexToString( crsm.payload );
                value = issuer2 != "" ? issuer2 : "unknown";
                info.insert( "issuer", value );
            }
        }
        theModem.data().simIssuer = value.get_string();

        /* Phonebooks */
        var cpbs = theModem.createAtCommand<PlusCPBS>( "+CPBS" );
        response = yield theModem.processAtCommandAsync( cpbs, cpbs.test() );
        var pbnames = "";
        if ( cpbs.validateTest( response ) == Constants.AtResponse.VALID )
        {
            foreach ( var pbcode in cpbs.phonebooks )
            {
                pbnames += Constants.instance().simPhonebookCodeToString( pbcode );
                pbnames += " ";
            }
        }
        info.insert( "phonebooks", pbnames.strip() );

        /* Messages */
        var cpms = theModem.createAtCommand<PlusCPMS>( "+CPMS" );
        response = yield theModem.processAtCommandAsync( cpms, cpms.query() );
        if ( cpms.validate( response ) == Constants.AtResponse.VALID )
        {
            info.insert( "slots", cpms.total );
            info.insert( "used", cpms.used );
        }
    }
}

public class AtSimGetPhonebookInfo : SimGetPhonebookInfo
{
    public override async void run( string category, out int slots, out int numberlength, out int namelength ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cat = Constants.instance().simPhonebookStringToCode( category );
        if ( cat == "" )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Invalid category" );
        }

        var cmd = theModem.createAtCommand<PlusCPBW>( "+CPBW" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.test( cat ) );
        checkTestResponseValid( cmd, response );
        slots = cmd.max;
        numberlength = cmd.nlength;
        namelength = cmd.tlength;
    }
}

public class AtSimGetServiceCenterNumber : SimGetServiceCenterNumber
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusCSCA>( "+CSCA" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.query() );
        checkResponseValid( cmd, response );
        number = cmd.number;
    }
}

public class AtSimGetUnlockCounters : SimGetUnlockCounters
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }
}

public class AtSimRetrieveMessage : SimRetrieveMessage
{
    public override async void run( int index, out string status, out string number, out string contents, out GLib.HashTable<string,GLib.Variant> properties ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        properties = new GLib.HashTable<string,Variant>( str_hash, str_equal );

        var cmgr = theModem.createAtCommand<PlusCMGR>( "+CMGR" );
        var response = yield theModem.processAtCommandAsync( cmgr, cmgr.issue( index ) );
        checkMultiResponseValid( cmgr, response );

        var sms = Sms.Message.newFromHexPdu( cmgr.hexpdu, cmgr.tpdulen );
        status = Constants.instance().simMessagebookStatusToString( cmgr.status );
        number = sms.number();
        contents = sms.to_string();
        properties = sms.properties();
    }
}

public class AtSimRetrievePhonebook : SimRetrievePhonebook
{
    public override async void run( string category, int mindex, int maxdex ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cat = Constants.instance().simPhonebookStringToCode( category );
        if ( cat == "" )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Invalid Category" );
        }

        phonebook = theModem.pbhandler.storage.phonebook( cat, mindex, maxdex );
    }
}

public class AtSimSetAuthCodeRequired : SimSetAuthCodeRequired
{
    public override async void run( bool required, string pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusCLCK>( "+CLCK" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( "SC", required, pin ) );
        checkResponseOk( cmd, response );
    }
}

public class AtSimSendAuthCode : SimSendAuthCode
{
    public override async void run( string pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusCPIN>( "+CPIN" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( pin ) );
        var code = checkResponseExpected( cmd, response,
            { Constants.AtResponse.OK, Constants.AtResponse.CME_ERROR_016_INCORRECT_PASSWORD } );

        if ( code == Constants.AtResponse.CME_ERROR_016_INCORRECT_PASSWORD )
        {
            throw new FreeSmartphone.GSM.Error.SIM_AUTH_FAILED( @"PIN $pin not accepted" );
        }
        else
        {
            // PIN seems known good, save for later
            theModem.data().simPin = pin;
        }
        //FIXME: Was it intended to do this in background? (i.e. not yielding)
        gatherSimStatusAndUpdate();
    }
}

public class AtSimSendStoredMessage : SimSendStoredMessage
{
    public override async void run( int index ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusCMSS>( "+CMSS" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( index ) );
        checkResponseValid( cmd, response );
        transaction_index = cmd.refnum;

        //FIXME: What should we do with that?
        timestamp = "now";
    }
}

public class AtSimSetServiceCenterNumber : SimSetServiceCenterNumber
{
    public override async void run( string number ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        validatePhoneNumber( number );
        var cmd = theModem.createAtCommand<PlusCSCA>( "+CSCA" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( number ) );
        checkResponseOk( cmd, response );
    }
}

public class AtSimStoreMessage : SimStoreMessage
{
    public override async void run( string recipient_number, string contents, bool want_report ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        validatePhoneNumber( recipient_number );

        var hexpdus = theModem.smshandler.formatTextMessage( recipient_number, contents, want_report );

        if ( hexpdus.size != 1 )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( @"Message does not fit in one slot, would rather take $(hexpdus.size) slots" );
        }

        // send the SMS one after another
        foreach( var hexpdu in hexpdus )
        {
            var cmd = theModem.createAtCommand<PlusCMGW>( "+CMGW" );
            var response = yield theModem.processAtPduCommandAsync( cmd, cmd.issue( hexpdu ) );
            checkResponseValid( cmd, response );
            memory_index = cmd.memory_index;
        }
    }
}

public class AtSimUnlock : SimUnlock
{
    public override async void run( string puk, string newpin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusCPIN>( "+CPIN" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( puk, newpin ) );
        checkResponseOk( cmd, response );
    }
}

public class AtSimWriteEntry : SimWriteEntry
{
    public override async void run( string category, int index, string number, string name ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cat = Constants.instance().simPhonebookStringToCode( category );
        if ( cat == "" )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Invalid category" );
        }

        var cmd = theModem.createAtCommand<PlusCPBW>( "+CPBW" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( cat, index, number, name ) );
        checkResponseOk( cmd, response );
    }
}

/**
 * SMS Mediators
 **/
public class AtSmsRetrieveTextMessages : SmsRetrieveTextMessages
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        //FIXME: Bug in Vala
        //messagebook = theModem.smshandler.storage.messagebook();
        //FIXME: Work around
        var array = theModem.smshandler.storage.messagebook();
        messagebook = new FreeSmartphone.GSM.SIMMessage[array.length] {};
        for( int i = 0; i < array.length; ++i )
        {
            messagebook[i] = array[i];
        }
    }
}

public class AtSmsGetSizeForTextMessage : SmsGetSizeForTextMessage
{
    public override async void run( string contents ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var hexpdus = theModem.smshandler.formatTextMessage( "+123456789", contents, false );
        size = hexpdus.size;
    }
}

public class AtSmsSendTextMessage : SmsSendTextMessage
{
    public override async void run( string recipient_number, string contents, bool want_report ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        validatePhoneNumber( recipient_number );

        var hexpdus = theModem.smshandler.formatTextMessage( recipient_number, contents, want_report );

        // signalize that we're sending a couple of SMS
        var cmms = theModem.createAtCommand<PlusCMMS>( "+CMMS" );
        yield theModem.processAtCommandAsync( cmms, cmms.issue( 1 ) ); // not interested in the result

        // send the SMS one after another
        foreach( var hexpdu in hexpdus )
        {
            var cmd = theModem.createAtCommand<PlusCMGS>( "+CMGS" );
            var response = yield theModem.processAtPduCommandAsync( cmd, cmd.issue( hexpdu ) );
            checkResponseValid( cmd, response );
            hexpdu.transaction_index = cmd.refnum;
        }
        transaction_index = theModem.smshandler.lastReferenceNumber();
        //FIXME: What about ACK PDUs?
        timestamp = "now";

        // signalize that we're done
        yield theModem.processAtCommandAsync( cmms, cmms.issue( 0 ) ); // not interested in the result

        // remember transaction indizes for later
        if ( want_report )
        {
            theModem.smshandler.storeTransactionIndizesForSentMessage( hexpdus );
        }
    }
}

/**
 * Network Mediators
 **/
public class AtNetworkGetSignalStrength : NetworkGetSignalStrength
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusCSQ>( "+CSQ" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.execute() );
        checkResponseValid( cmd, response );
        signal = cmd.signal;
    }
}

public class AtNetworkGetStatus : NetworkGetStatus
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
#if 0
        if ( theModem.data().simIssuer == null )
        {
            var mediator = new AtSimGetInformation();
            yield mediator.run();
        }
#endif
        status = new GLib.HashTable<string,Variant>( str_hash, str_equal );
        Variant strvalue;
        Variant intvalue;

        // query field strength
        var csq = theModem.createAtCommand<PlusCSQ>( "+CSQ" );
        var response = yield theModem.processAtCommandAsync( csq, csq.execute() );
        if ( csq.validate( response ) == Constants.AtResponse.VALID )
        {
            intvalue = csq.signal;
            status.insert( "strength", intvalue );
        }
#if 0
        bool overrideProviderWithSimIssuer = false;
#endif
        // query telephony registration status and lac/cid
        var creg = theModem.createAtCommand<PlusCREG>( "+CREG" );
        var cregResult = yield theModem.processAtCommandAsync( creg, creg.query() );
        if ( creg.validate( cregResult ) == Constants.AtResponse.VALID )
        {
            var cregResult2 = yield theModem.processAtCommandAsync( creg, creg.queryFull( creg.mode ) );
            if ( creg.validate( cregResult2 ) == Constants.AtResponse.VALID )
            {
                strvalue = Constants.instance().networkRegistrationStatusToString( creg.status );
                status.insert( "registration", strvalue );
                strvalue = creg.lac;
                status.insert( "lac", strvalue );
                strvalue = creg.cid;
                status.insert( "cid", strvalue );
#if 0
                overrideProviderWithSimIssuer = ( theModem.data().simIssuer != null && creg.status == 1 /* home */ );
#endif
            }
        }

        // query registration mode, operator name, access technology
        var cops = theModem.createAtCommand<PlusCOPS>( "+COPS" );
        var copsResult = yield theModem.processAtCommandAsync( cops, cops.query( PlusCOPS.Format.ALPHANUMERIC ) );
        if ( cops.validate( copsResult ) == Constants.AtResponse.VALID )
        {
            strvalue = Constants.instance().networkRegistrationModeToString( cops.mode );
            status.insert( "mode", strvalue );
            strvalue = cops.oper;
            status.insert( "provider", strvalue );
            status.insert( "network", strvalue ); // base value
            status.insert( "display", strvalue ); // base value
            strvalue = cops.act;
            status.insert( "act", strvalue );
        }
        else if ( cops.validate( copsResult ) == Constants.AtResponse.CME_ERROR_030_NO_NETWORK_SERVICE )
        {
            status.insert( "registration", "unregistered" );
        }

        // query operator display name
        var copsResult2 = yield theModem.processAtCommandAsync( cops, cops.query( PlusCOPS.Format.ALPHANUMERIC_SHORT ) );
        if ( cops.validate( copsResult2 ) == Constants.AtResponse.VALID )
        {
            // only override default, if set
            if ( cops.oper != "" )
            {
                strvalue = cops.oper;
                status.insert( "display", strvalue );
                status.insert( "network", strvalue );
            }
        }
#if 0
        // check whether we want to override display name with SIM issuer
        if ( overrideProviderWithSimIssuer )
        {
            status.insert( "display", theModem.data().simIssuer );
        }
#endif
        // query operator code
        var copsResult3 = yield theModem.processAtCommandAsync( cops, cops.query( PlusCOPS.Format.NUMERIC ) );
        if ( cops.validate( copsResult3 ) == Constants.AtResponse.VALID )
        {
            strvalue = cops.oper;
            status.insert( "code", strvalue );
        }

        // query pdp registration status and lac/cid
        var cgreg = theModem.createAtCommand<PlusCGREG>( "+CGREG" );
        var cgregResult = yield theModem.processAtCommandAsync( cgreg, cgreg.query() );
        if ( cgreg.validate( cgregResult ) == Constants.AtResponse.VALID )
        {
            var cgregResult2 = yield theModem.processAtCommandAsync( cgreg, cgreg.queryFull( cgreg.mode ) );
            if ( cgreg.validate( cgregResult2 ) == Constants.AtResponse.VALID )
            {
                strvalue = Constants.instance().networkRegistrationStatusToString( cgreg.status );
                status.insert( "pdp.registration", strvalue );
                strvalue = cgreg.lac;
                status.insert( "pdp.lac", strvalue );
                strvalue = cgreg.cid;
                status.insert( "pdp.cid", strvalue );
            }
        }
    }
}

public class AtNetworkListProviders : NetworkListProviders
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusCOPS>( "+COPS" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.test() );
        checkTestResponseValid( cmd, response );
        providers = cmd.providers;
    }
}

public class AtNetworkRegister : NetworkRegister
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusCOPS>( "+COPS" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( PlusCOPS.Action.REGISTER_WITH_BEST_PROVIDER ) );
        checkResponseOk( cmd, response );
    }
}

public class AtNetworkUnregister : NetworkUnregister
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusCOPS>( "+COPS" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( PlusCOPS.Action.UNREGISTER ) );
        checkResponseOk( cmd, response );
    }
}

public class AtNetworkSendUssdRequest : NetworkSendUssdRequest
{
    public override async void run( string request ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusCUSD>( "+CUSD" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.query( request ) );
        checkResponseOk( cmd, response );
    }
}

public class AtNetworkGetCallingId : NetworkGetCallingId
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusCLIR>( "+CLIR" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.query() );
        checkResponseValid( cmd, response );
        status = (FreeSmartphone.GSM.CallingIdentificationStatus) cmd.value;
    }
}

public class AtNetworkSetCallingId : NetworkSetCallingId
{
    public override async void run( FreeSmartphone.GSM.CallingIdentificationStatus status ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusCLIR>( "+CLIR" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( status ) );
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
        var response = yield theModem.processAtCommandAsync( cmd, cmd.execute() );
        checkMultiResponseValid( cmd, response );
        calls = cmd.calls;
    }
}

public class AtCallSendDtmf : CallSendDtmf
{
    public override async void run( string tones ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusVTS>( "+VTS" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( tones ) );
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
public class AtPdpActivateContext : PdpActivateContext
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var data = theModem.data();
        if ( data.contextParams == null )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "No credentials set. Call org.freesmartphone.GSM.PDP.SetCredentials first." );
        }
        yield theModem.pdphandler.activate();
    }
}

public class AtPdpDeactivateContext : PdpDeactivateContext
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        yield theModem.pdphandler.deactivate();
    }
}

public class AtPdpGetCredentials : PdpGetCredentials
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var data = theModem.data();
        if ( data.contextParams == null )
        {
            apn = "";
            username = "";
            password = "";
        }
        else
        {
            apn = data.contextParams.apn;
            username = data.contextParams.username;
            password = data.contextParams.password;
        }
    }
}

public class AtPdpSetCredentials : PdpSetCredentials
{
    public override async void run( string apn, string username, string password ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var data = theModem.data();
        data.contextParams = new ContextParams( apn, username, password );

        var cmd = theModem.createAtCommand<PlusCGDCONT>( "+CGDCONT" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( apn ) );
        checkResponseOk( cmd, response );
    }
}

/**
 * CB Mediators
 **/
public class AtCbSetCellBroadcastSubscriptions : CbSetCellBroadcastSubscriptions
{
    public override async void run( string subscriptions ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        if ( ! ( subscriptions in new string[] { "none", "all" } ) )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Must use 'none' or 'all' as parameter." );
        }
        var cmd = theModem.createAtCommand<PlusCSCB>( "+CSCB" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( subscriptions == "all" ? PlusCSCB.Mode.ALL : PlusCSCB.Mode.NONE ) );
        checkResponseOk( cmd, response );
    }
}

public class AtCbGetCellBroadcastSubscriptions : CbGetCellBroadcastSubscriptions
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusCSCB>( "+CSCB" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.query() );
        checkResponseValid( cmd, response );
        if ( cmd.mode == PlusCSCB.Mode.ALL )
        {
            subscriptions = "all";
        }
        else
        {
            subscriptions = "none";
        }
    }
}

/**
 * Monitor Mediators
 **/
public class AtMonitorGetServingCellInformation : MonitorGetServingCellInformation
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.UNSUPPORTED( "Not implemented" );
    }
}

public class AtMonitorGetNeighbourCellInformation : MonitorGetNeighbourCellInformation
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.UNSUPPORTED( "Not implemented" );
    }
}

/**
 * Voice Mailbox Mediators
 **/
public class AtVoiceMailboxGetNumber : VoiceMailboxGetNumber
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.UNSUPPORTED( "Not implemented" );
    }
}

public class AtVoiceMailboxSetNumber : VoiceMailboxSetNumber
{
    public override async void run( string number ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.UNSUPPORTED( "Not implemented" );
    }
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
