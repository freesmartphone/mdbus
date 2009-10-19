/**
 * Copyright (C) 2009 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
 * Some helper functions useful for mediators
 **/
internal async void gatherSpeakerVolumeRange()
{
    var data = theModem.data();
    if ( data.speakerVolumeMinimum == -1 )
    {
        var clvl = theModem.createAtCommand<PlusCLVL>( "+CLVL" );
        var response = yield theModem.processCommandAsync( clvl, clvl.test() );
        if ( clvl.validateTest( response ) == AtResponse.VALID )
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

internal async void gatherSimStatusAndUpdate()
{
    var data = theModem.data();

    var cmd = theModem.createAtCommand<PlusCPIN>( "+CPIN" );
    var response = yield theModem.processCommandAsync( cmd, cmd.query() );
    if ( cmd.validate( response ) == AtResponse.VALID )
    {
        if ( cmd.status != data.simAuthStatus )
        {
            data.simAuthStatus = cmd.status;
            theModem.logger.info( "SIM Auth status changed to '%s'".printf( FsoFramework.StringHandling.enumToString( typeof(FreeSmartphone.GSM.SIMAuthStatus), cmd.status ) ) );
            // send dbus signal
            var obj = theModem.theDevice<FreeSmartphone.GSM.SIM>();
            obj.auth_status( cmd.status );
            //TODO: advance modem status?
        }
    }
}

internal async void gatherPhonebookParams()
{
    var data = theModem.data();
    if ( data.simPhonebooks.size == 0 )
    {
        var cmd = theModem.createAtCommand<PlusCPBS>( "+CPBS" );
        var response = yield theModem.processCommandAsync( cmd, cmd.test() );
        if ( cmd.validateTest( response ) == AtResponse.VALID )
        {
            foreach ( var pbname in cmd.phonebooks )
            {
                var cpbr = theModem.createAtCommand<PlusCPBR>( "+CPBR" );
                var pbcode = Constants.instance().simPhonebookStringToName( pbname );
                var answer = yield theModem.processCommandAsync( cpbr, cpbr.test( pbcode ) );
                if ( cpbr.validateTest( answer ) == AtResponse.VALID )
                {
                    data.simPhonebooks[pbname] = new PhonebookParams( cpbr.min, cpbr.max );
                    assert( theModem.logger.debug( @"Found phonebook '$pbname' w/ indices $(cpbr.min)-$(cpbr.max)" ) );
                }
            }
        }
        else
        {
            theModem.logger.warning( "Modem does not support querying the phonebooks." );
        }
    }
}

internal void updateSimStatus( FreeSmartphone.GSM.SIMAuthStatus status )
{
    var data = theModem.data();
    
}

/**
 * Device Mediators
 **/
public class AtDeviceGetAntennaPower : DeviceGetAntennaPower
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cfun = theModem.createAtCommand<PlusCFUN>( "+CFUN" );
        var response = yield theModem.processCommandAsync( cfun, cfun.query() );
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
        var response = yield theModem.processCommandAsync( cmd, cmd.query() );
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
        var response = yield theModem.processCommandAsync( cmd, cmd.query() );
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
        var response = yield theModem.processCommandAsync( cfun, cfun.query() );
        checkResponseValid( cfun, response );
        level = Constants.instance().deviceFunctionalityStatusToString( cfun.value );
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
        if ( cgmr.validate( response ) == AtResponse.VALID )
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
        if ( cgmm.validate( response ) == AtResponse.VALID )
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
        if ( cgmi.validate( response ) == AtResponse.VALID )
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
        if ( cgsn.validate( response ) == AtResponse.VALID )
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
        if ( cmickey.validate( response ) == AtResponse.VALID )
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
        var response = yield theModem.processCommandAsync( gcap, gcap.execute() );
        if ( gcap.validate( response ) == AtResponse.VALID )
        {
            if ( "GSM" in gcap.value )
            {
                value = (string) "TA";
                features.insert( "gsm", value );
            }
        }

        var cgclass = theModem.createAtCommand<PlusCGCLASS>( "+CGCLASS" );
        response = yield theModem.processCommandAsync( cgclass, cgclass.test() );
        if ( cgclass.validateTest( response ) == AtResponse.VALID )
        {
            value = (string) cgclass.righthandside;
            features.insert( "gprs", value );
        }

        var fclass = theModem.createAtCommand<PlusFCLASS>( "+FCLASS" );
        response = yield theModem.processCommandAsync( fclass, fclass.test() );
        if ( fclass.validateTest( response ) == AtResponse.VALID )
        {
            value = (string) fclass.faxclass;
            features.insert( "fax", value );
        }
    }
}

public class AtDeviceGetMicrophoneMuted : DeviceGetMicrophoneMuted
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusCMUT>( "+CMUT" );
        var response = yield theModem.processCommandAsync( cmd, cmd.query() );
        checkResponseValid( cmd, response );
        muted = cmd.value == 1;
    }
}

public class AtDeviceGetSimBuffersSms : DeviceGetSimBuffersSms
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusCNMI>( "+CNMI" );
        var response = yield theModem.processCommandAsync( cmd, cmd.query() );
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
        var response = yield theModem.processCommandAsync( cmd, cmd.query() );
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
        var response = yield theModem.processCommandAsync( cmd, cmd.execute() );

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
        var response = yield theModem.processCommandAsync( cmd, since_epoch > 0 ? cmd.issue( t.year+1900-2000, t.month+1, t.day, t.hour, t.minute, t.second, 0 ) : cmd.clear() );

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
        var response = yield theModem.processCommandAsync( cmd, cmd.issue( t.year+1900-2000, t.month+1, t.day, t.hour, t.minute, t.second, 0 ) );

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
    public override async void run( string level ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var value = Constants.instance().deviceFunctionalityStringToStatus( level );

        if ( value == -1 )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Functionality needs to be one of \"minimal\", \"airplane\", or \"full\"." );
        }

        var cmd = theModem.createAtCommand<PlusCFUN>( "+CFUN" );
        var response = yield theModem.processCommandAsync( cmd, cmd.issue( value ) );
        checkResponseOk( cmd, response );

        yield gatherSimStatusAndUpdate();
    }
}

public class AtDeviceSetMicrophoneMuted : DeviceSetMicrophoneMuted
{
    public override async void run( bool muted ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmut = theModem.createAtCommand<PlusCMUT>( "+CMUT" );
        var response = yield theModem.processCommandAsync( cmut, cmut.issue( muted ? 1 : 0 ) );

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
            var response = yield theModem.processCommandAsync( cnmi, cnmi.issue( cnmiparams.mode,
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
        var response = yield theModem.processCommandAsync( clvl, clvl.issue( value ) );
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
        var response = yield theModem.processCommandAsync( cmd, cmd.issue( "SC", oldpin, newpin ) );
        checkResponseOk( cmd, response );
    }
}

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
        if ( cimi.validate( response ) == AtResponse.VALID )
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
                Constants.SimCommand.READ_BINARY,
                Constants.instance().simFilesystemEntryNameToCode( "EFspn" ), 0, 0, 17 ) );
        if ( crsm.validate( response ) == AtResponse.VALID )
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

public class AtSimGetServiceCenterNumber : SimGetServiceCenterNumber
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusCSCA>( "+CSCA" );
        var response = yield theModem.processCommandAsync( cmd, cmd.query() );
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
        var a = new string[] {};
        foreach ( var key in data.simPhonebooks.keys )
        {
            a += key;
        }
        phonebooks = a;
        //FIXME: This doesn't work, returns an empty array -- bug in libgee?
        //phonebooks = (string[]) data.simPhonebooks.keys.to_array();
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
        var response = yield theModem.processCommandAsync( cmd, cmd.issue( cat, pp.min, pp.max ) );

        checkMultiResponseValid( cmd, response );
        phonebook = cmd.phonebook;
    }
}

public class AtSimRetrieveMessagebook : SimRetrieveMessagebook
{
    public override async void run( string category ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.SYSTEM_ERROR( "Not yet implemented" );
    }
}

public class AtSimSendAuthCode : SimSendAuthCode
{
    public override async void run( string pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusCPIN>( "+CPIN" );
        var response = yield theModem.processCommandAsync( cmd, cmd.issue( pin ) );
        checkResponseOk( cmd, response );
    }
}

public class AtSimSetServiceCenterNumber : SimSetServiceCenterNumber
{
    public override async void run( string number ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusCSCA>( "+CSCA" );
        var response = yield theModem.processCommandAsync( cmd, cmd.issue( number ) );
        checkResponseOk( cmd, response );
    }
}

public class AtSimUnlock : SimUnlock
{
    public override async void run( string puk, string newpin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusCPIN>( "+CPIN" );
        var response = yield theModem.processCommandAsync( cmd, cmd.issue( puk, newpin ) );
        checkResponseOk( cmd, response );
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
        var response = yield theModem.processCommandAsync( cmd, cmd.execute() );
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
        var response = yield theModem.processCommandAsync( csq, csq.execute() );
        if ( csq.validate( response ) == AtResponse.VALID )
        {
            intvalue = csq.signal;
            status.insert( "strength", intvalue );
        }

        // query registration status and lac/cid
        var creg = theModem.createAtCommand<PlusCREG>( "+CREG" );
        var cregResult = yield theModem.processCommandAsync( creg, creg.query() );
        if ( creg.validate( cregResult ) == AtResponse.VALID )
        {
            var cregResult2 = yield theModem.processCommandAsync( creg, creg.queryFull( creg.mode ) );
            if ( creg.validate( cregResult2 ) == AtResponse.VALID )
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
        var copsResult = yield theModem.processCommandAsync( cops, cops.query( PlusCOPS.Format.ALPHANUMERIC ) );
        if ( cops.validate( copsResult ) == AtResponse.VALID )
        {
            strvalue = Constants.instance().networkRegistrationModeToString( cops.mode );
            status.insert( "mode", strvalue );
            strvalue = cops.oper;
            status.insert( "provider", strvalue );
            strvalue = cops.act;
            status.insert( "act", strvalue );
        }

        // query operator code
        var copsResult2 = yield theModem.processCommandAsync( cops, cops.query( PlusCOPS.Format.NUMERIC ) );
        if ( cops.validate( copsResult2 ) == AtResponse.VALID )
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
        var response = yield theModem.processCommandAsync( cmd, cmd.test() );
        checkResponseOk( cmd, response );
        providers = cmd.providers;
    }
}

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
 * Register all mediators
 **/
public void registerGenericAtMediators( HashMap<Type,Type> table )
{
    // register commands
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
    table[ typeof(SimGetAuthStatus) ]             = typeof( AtSimGetAuthStatus );
    table[ typeof(SimGetServiceCenterNumber) ]    = typeof( AtSimGetServiceCenterNumber );
    table[ typeof(SimGetInformation) ]            = typeof( AtSimGetInformation );
    table[ typeof(SimListPhonebooks) ]            = typeof( AtSimListPhonebooks );
    table[ typeof(SimRetrievePhonebook) ]         = typeof( AtSimRetrievePhonebook );
    table[ typeof(SimSendAuthCode) ]              = typeof( AtSimSendAuthCode );
    table[ typeof(SimSetServiceCenterNumber) ]    = typeof( AtSimSetServiceCenterNumber );
    table[ typeof(SimUnlock) ]                    = typeof( AtSimUnlock );

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
}

} // namespace FsoGsm
