/*
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
 * Device Mediators
 **/
public class AtDeviceGetAlarmTime : DeviceGetAlarmTime
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var data = modem.data();
        var cmd = modem.createAtCommand<PlusCALA>( "+CALA" );
        var response = yield modem.processAtCommandAsync( cmd, cmd.query() );
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
        var cmd = modem.createAtCommand<PlusCCLK>( "+CCLK" );
        var response = yield modem.processAtCommandAsync( cmd, cmd.query() );
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
        var cfun = modem.createAtCommand<PlusCFUN>( "+CFUN" );
        var response = yield modem.processAtCommandAsync( cfun, cfun.query() );
        checkResponseValid( cfun, response );
        level = Constants.deviceFunctionalityStatusToString( cfun.value );
        autoregister = modem.data().keepRegistration;
        pin = modem.data().simPin;
    }
}

public class AtDeviceGetInformation : DeviceGetInformation
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        info = new GLib.HashTable<string,Variant>( str_hash, str_equal );

        Variant value;

        var cgmr = modem.createAtCommand<PlusCGMR>( "+CGMR" );
        var response = yield modem.processAtCommandAsync( cgmr, cgmr.execute() );
        if ( cgmr.validate( response ) == Constants.AtResponse.VALID )
        {
            value = (string) cgmr.value;
            info.insert( "revision", value );
        }
        else
        {
            info.insert( "revision", "unknown" );
        }

        var cgmm = modem.createAtCommand<PlusCGMM>( "+CGMM" );
        response = yield modem.processAtCommandAsync( cgmm, cgmm.execute() );
        if ( cgmm.validate( response ) == Constants.AtResponse.VALID )
        {
            value = (string) cgmm.value;
            info.insert( "model", value );
        }
        else
        {
            info.insert( "model", "unknown" );
        }

        var cgmi = modem.createAtCommand<PlusCGMI>( "+CGMI" );
        response = yield modem.processAtCommandAsync( cgmi, cgmi.execute() );
        if ( cgmi.validate( response ) == Constants.AtResponse.VALID )
        {
            value = (string) cgmi.value;
            info.insert( "manufacturer", value );
        }
        else
        {
            info.insert( "manufacturer", "unknown" );
        }

        var cgsn = modem.createAtCommand<PlusCGSN>( "+CGSN" );
        response = yield modem.processAtCommandAsync( cgsn, cgsn.execute() );
        if ( cgsn.validate( response ) == Constants.AtResponse.VALID )
        {
            value = (string) cgsn.value;
            info.insert( "imei", value );
        }
        else
        {
            info.insert( "imei", "unknown" );
        }

        var cmickey = modem.createAtCommand<PlusCMICKEY>( "+CMICKEY" );
        response = yield modem.processAtCommandAsync( cmickey, cmickey.execute() );
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
        var data = modem.data();
        features.insert( "gsm", data.supportsGSM );
        features.insert( "voice", data.supportsVoice );
        features.insert( "cdma", data.supportsCDMA );
        features.insert( "csd", data.supportsCSD );
        features.insert( "fax", data.supportsFAX );

        // now some additional runtime checks

        // GSM?
        var gcap = modem.createAtCommand<PlusGCAP>( "+GCAP" );
        var response = yield modem.processAtCommandAsync( gcap, gcap.execute() );
        if ( gcap.validate( response ) == Constants.AtResponse.VALID )
        {
            if ( "GSM" in gcap.value || data.supportsGSM )
            {
                features.insert( "gsm", true );
            }
        }
        // PDP?
        var cgclass = modem.createAtCommand<PlusCGCLASS>( "+CGCLASS" );
        response = yield modem.processAtCommandAsync( cgclass, cgclass.test() );
        if ( cgclass.validateTest( response ) == Constants.AtResponse.VALID )
        {
            features.insert( "gprs", cgclass.righthandside );
        }
        // FAX?
        var fclass = modem.createAtCommand<PlusFCLASS>( "+FCLASS" );
        response = yield modem.processAtCommandAsync( fclass, fclass.test() );
        if ( fclass.validateTest( response ) == Constants.AtResponse.VALID )
        {
            features.insert( "fax", fclass.righthandside );
        }
        // facilities
        var fac = modem.createAtCommand<PlusCLCK>( "+CLCK" );
        response = yield modem.processAtCommandAsync( fac, fac.test() );
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
        var cmd = modem.createAtCommand<PlusCMUT>( "+CMUT" );
        var response = yield modem.processAtCommandAsync( cmd, cmd.query() );
        checkResponseValid( cmd, response );
        muted = cmd.value == 1;
    }
}

public class AtDeviceGetSimBuffersSms : DeviceGetSimBuffersSms
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = modem.createAtCommand<PlusCNMI>( "+CNMI" );
        var response = yield modem.processAtCommandAsync( cmd, cmd.query() );
        checkResponseValid( cmd, response );
        buffers = cmd.mt < 2;
    }
}

public class AtDeviceGetSpeakerVolume : DeviceGetSpeakerVolume
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        yield gatherSpeakerVolumeRange( modem );

        var cmd = modem.createAtCommand<PlusCLVL>( "+CLVL" );
        var response = yield modem.processAtCommandAsync( cmd, cmd.query() );
        checkResponseValid( cmd, response );

        var data = modem.data();
        var interval = 100.0 / ( data.speakerVolumeMaximum - data.speakerVolumeMinimum );
        volume = data.speakerVolumeMinimum + (int) Math.round( cmd.value * interval );
    }
}

public class AtDeviceGetPowerStatus : DeviceGetPowerStatus
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = modem.createAtCommand<PlusCBC>( "+CBC" );
        var response = yield modem.processAtCommandAsync( cmd, cmd.execute() );
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

        var cmd = modem.createAtCommand<PlusCALA>( "+CALA" );
        var response = yield modem.processAtCommandAsync( cmd, since_epoch > 0 ? cmd.issue( t.year+1900-2000, t.month+1, t.day, t.hour, t.minute, t.second, 0 ) : cmd.clear() );

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

        var cmd = modem.createAtCommand<PlusCCLK>( "+CCLK" );
        var response = yield modem.processAtCommandAsync( cmd, cmd.issue( t.year+1900-2000, t.month+1, t.day, t.hour, t.minute, t.second, 0 ) );

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
        var value = Constants.deviceFunctionalityStringToStatus( level );

        if ( value == -1 )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Functionality needs to be one of \"minimal\", \"airplane\", or \"full\"." );
        }

        var cmd = modem.createAtCommand<PlusCFUN>( "+CFUN" );
        var queryanswer = yield modem.processAtCommandAsync( cmd, cmd.query() );
        checkResponseValid( cmd, queryanswer );
        var curlevel = Constants.deviceFunctionalityStatusToString( cmd.value );
        if ( curlevel != level )
        {
            var response = yield modem.processAtCommandAsync( cmd, cmd.issue( value ) );
            checkResponseExpected( cmd,
                response,
                { Constants.AtResponse.OK, Constants.AtResponse.CME_ERROR_011_SIM_PIN_REQUIRED } );
        }
        var data = modem.data();
        data.keepRegistration = autoregister;
        if ( pin != "" )
        {
            data.simPin = pin;
            modem.watchdog.resetUnlockMarker();
        }
        yield gatherSimStatusAndUpdate( modem );
    }
}

public class AtDeviceSetMicrophoneMuted : DeviceSetMicrophoneMuted
{
    public override async void run( bool muted ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmut = modem.createAtCommand<PlusCMUT>( "+CMUT" );
        var response = yield modem.processAtCommandAsync( cmut, cmut.issue( muted ? 1 : 0 ) );

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

        yield gatherSpeakerVolumeRange( modem );

        var data = modem.data();
        var interval = (double)( data.speakerVolumeMaximum - data.speakerVolumeMinimum ) / 100.0;
        var value = data.speakerVolumeMinimum + (int) Math.round( volume * interval );

        var clvl = modem.createAtCommand<PlusCLVL>( "+CLVL" );
        var response = yield modem.processAtCommandAsync( clvl, clvl.issue( value ) );
        checkResponseOk( clvl, response );
    }
}

} // namespace FsoGsm

// vim:ts=4:sw=4:expandtab
