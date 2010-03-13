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
internal void throwAppropriateError( Constants.AtResponse code, string detail ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
{
    var error = Constants.instance().atResponseCodeToError( code, detail );
    throw error;
}

/**
 * Throws an error if response is not OK
 **/
internal void checkResponseOk( FsoGsm.AtCommand command, string[] response ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
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
internal Constants.AtResponse checkResponseExpected( FsoGsm.AtCommand command,
                                     string[] response,
                                     Constants.AtResponse[] expected
                                   ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
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

internal void checkResponseConnect( FsoGsm.AtCommand command, string[] response ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
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

internal void checkTestResponseValid( FsoGsm.AtCommand command, string[] response ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
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

internal void checkResponseValid( FsoGsm.AtCommand command, string[] response ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
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

internal void checkMultiResponseValid( FsoGsm.AtCommand command, string[] response ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
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

internal void validatePhoneNumber( string number ) throws FreeSmartphone.Error
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
public async void gatherSpeakerVolumeRange() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
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

public async void gatherSimStatusAndUpdate() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
{
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
            if ( modemStatus == Modem.Status.INITIALIZING )
            {
                if ( cmd.status == FreeSmartphone.GSM.SIMAuthStatus.READY )
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
}

public async void gatherPhonebookParams() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
{
    var data = theModem.data();
    if ( data.simPhonebooks.size == 0 )
    {
        var cmd = theModem.createAtCommand<PlusCPBS>( "+CPBS" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.test() );
        checkTestResponseValid( cmd, response );

        foreach ( var pbname in cmd.phonebooks )
        {
            var cpbr = theModem.createAtCommand<PlusCPBR>( "+CPBR" );
            var pbcode = Constants.instance().simPhonebookStringToName( pbname );
            var answer = yield theModem.processAtCommandAsync( cpbr, cpbr.test( pbcode ) );
            if ( cpbr.validateTest( answer ) == Constants.AtResponse.VALID )
            {
                data.simPhonebooks[pbname] = new PhonebookParams( cpbr.min, cpbr.max );
                assert( theModem.logger.debug( @"Found phonebook '$pbname' w/ indices $(cpbr.min)-$(cpbr.max)" ) );
            }
        }
    }
}

public async void triggerUpdateNetworkStatus()
{
    // gather info
    var m = theModem.createMediator<FsoGsm.NetworkGetStatus>();
    yield m.run();

    // advance modem status, if necessary
    var status = m.status.lookup( "registration" ).get_string();

    assert( theModem.logger.debug( @"triggerUpdateNetworkStatus() status = $status" ) );

    if ( status == "home" || status == "roaming" )
    {
        theModem.advanceToState( Modem.Status.ALIVE_REGISTERED );
    }

    // send dbus signal
    var obj = theModem.theDevice<FreeSmartphone.GSM.Network>();
    obj.status( m.status );
}

/**
 * Debug Mediators
 **/
public class AtDebugCommand : DebugCommand
{
    public override async void run( string command, string category ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<CustomAtCommand>( "CUSTOM" );

        AtChannel channel = theModem.channel( category ) as AtChannel;
        //FIXME: assert channel is really an At channel
        if ( channel == null )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( @"Channel $category not known" );
        }

        var response = yield channel.enqueueAsync( cmd, command, 0 );
        var result = "";
        for ( int i = 0; i < response.length-1; ++i )
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
public class AtDeviceGetAntennaPower : DeviceGetAntennaPower
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cfun = theModem.createAtCommand<PlusCFUN>( "+CFUN" );
        var response = yield theModem.processAtCommandAsync( cfun, cfun.query() );
        checkResponseValid( cfun, response );
        antenna_power = cfun.value == 1;
    }
}

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
        info = new GLib.HashTable<string,Value?>( str_hash, str_equal );

        var value = Value( typeof(string) );

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
        features = new GLib.HashTable<string,Value?>( str_hash, str_equal );
        var value = Value( typeof(string) );

        var gcap = theModem.createAtCommand<PlusGCAP>( "+GCAP" );
        var response = yield theModem.processAtCommandAsync( gcap, gcap.execute() );
        if ( gcap.validate( response ) == Constants.AtResponse.VALID )
        {
            if ( "GSM" in gcap.value )
            {
                value = (string) "TA";
                features.insert( "gsm", value );
            }
        }

        var cgclass = theModem.createAtCommand<PlusCGCLASS>( "+CGCLASS" );
        response = yield theModem.processAtCommandAsync( cgclass, cgclass.test() );
        if ( cgclass.validateTest( response ) == Constants.AtResponse.VALID )
        {
            value = (string) cgclass.righthandside;
            features.insert( "gprs", value );
        }
        else
        {
            // default these days is B
            value = (string) "B";
            features.insert( "gprs", "B" );
        }

        var fclass = theModem.createAtCommand<PlusFCLASS>( "+FCLASS" );
        response = yield theModem.processAtCommandAsync( fclass, fclass.test() );
        if ( fclass.validateTest( response ) == Constants.AtResponse.VALID )
        {
            value = (string) fclass.righthandside;
            features.insert( "fax", value );
        }

        var fac = theModem.createAtCommand<PlusCLCK>( "+CLCK" );
        response = yield theModem.processAtCommandAsync( fac, fac.test() );
        if ( fac.validateTest( response ) == Constants.AtResponse.VALID )
        {
            value = (string) fac.facilities;
            features.insert( "facilities", value );
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
        volume = data.speakerVolumeMinimum + cmd.value * 100 / ( data.speakerVolumeMaximum - data.speakerVolumeMinimum );
    }
}

public class AtDeviceGetPowerStatus : DeviceGetPowerStatus
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusCBC>( "+CBC" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.execute() );

        checkResponseValid( cmd, response );
        status = cmd.status;
        level = cmd.level;
    }
}

public class AtDeviceSetAlarmTime : DeviceSetAlarmTime
{
    public override async void run( int since_epoch ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var data = theModem.data();
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
        var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( value ) );
        checkResponseExpected( cmd,
                         response,
                         { Constants.AtResponse.OK, Constants.AtResponse.CME_ERROR_011_SIM_PIN_REQUIRED } );
        var data = theModem.data();
        data.keepRegistration = autoregister;
        data.simPin = pin;

        if ( pin != "" )
        {
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

public class AtDeviceSetSimBuffersSms : DeviceSetSimBuffersSms
{
    public override async void run( bool buffers ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        //if ( buffers != theModem.data().simBuffersSms )
        {
            var data = theModem.data();
            data.simBuffersSms = buffers;
            var cnmiparams = buffers ? data.cnmiSmsBufferedCb : data.cnmiSmsDirectCb;

            var cnmi = theModem.createAtCommand<PlusCNMI>( "+CNMI" );
            var response = yield theModem.processAtCommandAsync( cnmi, cnmi.issue( cnmiparams.mode,
                                                                                 cnmiparams.mt,
                                                                                 cnmiparams.bm,
                                                                                 cnmiparams.ds,
                                                                                 cnmiparams.bfr) );

            checkResponseOk( cnmi, response );
        }
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
        var value = data.speakerVolumeMinimum + volume * ( data.speakerVolumeMaximum - data.speakerVolumeMinimum ) / 100;

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

public class AtSimGetInformation : SimGetInformation
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        info = new GLib.HashTable<string,Value?>( str_hash, str_equal );

        var value = Value( typeof(string) );

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
        var response = yield theModem.processAtCommandAsync( cmd, cmd.query( "SC" ) );
        checkResponseValid( cmd, response );
        required = cmd.enabled;
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

public class AtSimListPhonebooks : SimListPhonebooks
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        yield gatherPhonebookParams();
        var data = theModem.data();
        //FIXME: This doesn't work, returns an empty array -- bug in libgee?
        //phonebooks = (string[]) data.simPhonebooks.keys.to_array();
        // slow workaround instead:
        var a = new string[] {};
        foreach ( var key in data.simPhonebooks.keys )
        {
            a += key;
        }
        phonebooks = a;
    }
}

public class AtSimRetrievePhonebook : SimRetrievePhonebook
{
    public override async void run( string category ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        yield gatherPhonebookParams();
        var data = theModem.data();

        if ( ! ( category in data.simPhonebooks ) )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Category needs to be one of ..." );
        }

        var cat = Constants.instance().simPhonebookStringToName( category );
        assert( category != "" );
        var pp = data.simPhonebooks[category];

        var cmd = theModem.createAtCommand<PlusCPBR>( "+CPBR" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( cat, pp.min, pp.max ) );

        var valid = cmd.validateMulti( response );
        if ( valid != Constants.AtResponse.VALID && valid != Constants.AtResponse.CME_ERROR_022_NOT_FOUND )
        {
            throwAppropriateError( valid, response[response.length-1] );
        }
        phonebook = cmd.phonebook;
    }
}

public class AtSimRetrieveMessagebook : SimRetrieveMessagebook
{
    public override async void run( string category ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        // ignore category for now

        //FIXME: Bug in Vala
        //messagebook = theModem.smshandler.storage.messagebook();
        //FIXME: Work around
        var array = theModem.smshandler.storage.messagebook();
        messagebook = new FreeSmartphone.GSM.SIMMessage[array.length] {};
        for( int i = 0; i < array.length; ++i )
        {
            messagebook[i] = array[i];
        }
#if DEBUG
        foreach ( var entry in messagebook )
        {
            debug( "%i %s %s %s, %p", entry.index, entry.number, entry.status, entry.contents, entry.properties );
        }
#endif
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

        gatherSimStatusAndUpdate();
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

public class AtSimUnlock : SimUnlock
{
    public override async void run( string puk, string newpin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusCPIN>( "+CPIN" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( puk, newpin ) );
        checkResponseOk( cmd, response );
    }
}

/**
 * SMS Mediators
 **/
public class AtSmsGetSizeForMessage : SmsGetSizeForMessage
{
    public override async void run( string contents ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var hexpdus = theModem.smshandler.formatTextMessage( "+123456789", contents );
        size = hexpdus.size;
    }
}

public class AtSmsSendMessage : SmsSendMessage
{
    public override async void run( string recipient_number, string contents, bool want_report ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        validatePhoneNumber( recipient_number );
        assert( contents != "" ); // only text messages supported for now
        uint8 refnum = 0;

        var hexpdus = theModem.smshandler.formatTextMessage( recipient_number, contents );

        // signalize that we're sending a couple of MMS
        var cmms = theModem.createAtCommand<PlusCMMS>( "+CMMS" );
        yield theModem.processAtCommandAsync( cmms, cmms.issue( 1 ) );

        // send the MMS one after another
        foreach( var hexpdu in hexpdus )
        {
            var cmd = theModem.createAtCommand<PlusCMGS>( "+CMGS" );
            var response = yield theModem.processAtPduCommandAsync( cmd, cmd.issue( hexpdu ) );
            checkResponseOk( cmd, response );
        }
        transaction_index = refnum;
        timestamp = "now";
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
        status = new GLib.HashTable<string,Value?>( str_hash, str_equal );
        var strvalue = Value( typeof(string) );
        var intvalue = Value( typeof(int) );

        // query field strength
        var csq = theModem.createAtCommand<PlusCSQ>( "+CSQ" );
        var response = yield theModem.processAtCommandAsync( csq, csq.execute() );
        if ( csq.validate( response ) == Constants.AtResponse.VALID )
        {
            intvalue = csq.signal;
            status.insert( "strength", intvalue );
        }

        // query registration status and lac/cid
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
            strvalue = cops.act;
            status.insert( "act", strvalue );
        }

        // query operator code
        var copsResult2 = yield theModem.processAtCommandAsync( cops, cops.query( PlusCOPS.Format.NUMERIC ) );
        if ( cops.validate( copsResult2 ) == Constants.AtResponse.VALID )
        {
            strvalue = cops.oper;
            status.insert( "code", strvalue );
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
 * Register all mediators
 **/
public void registerGenericAtMediators( HashMap<Type,Type> table )
{
    table[ typeof(DebugCommand) ]                 = typeof( AtDebugCommand );
    table[ typeof(DebugInjectResponse) ]          = typeof( AtDebugInjectResponse );
    table[ typeof(DebugPing) ]                    = typeof( AtDebugPing );

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
