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
        var channel = theModem.channel( "main" );

        var clvl = theModem.createAtCommand<PlusCLVL>( "+CLVL" );
        var response = yield channel.enqueueAsyncYielding( clvl, clvl.test() );
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

/**
 * Power on/off the antenna. THIS FUNCTION IS DEPRECATED
 **/
public class AtDeviceGetAntennaPower : DeviceGetAntennaPower
{
    public override async void run() throws FreeSmartphone.Error
    {
        var channel = theModem.channel( "main" );

        var cfun = theModem.createAtCommand<PlusCFUN>( "+CFUN" );
        var response = yield channel.enqueueAsyncYielding( cfun, cfun.query() );
        cfun.parse( response[0] );
        antenna_power = cfun.value == 1;
    }
}

/**
 * Get device information.
 **/
public class AtDeviceGetInformation : DeviceGetInformation
{
    public override async void run() throws FreeSmartphone.Error
    {
        info = new GLib.HashTable<string,Value?>( str_hash, str_equal );
        var channel = theModem.channel( "main" );
        var value = Value( typeof(string) );

        var cgmr = theModem.createAtCommand<PlusCGMR>( "+CGMR" );
        var response = yield channel.enqueueAsyncYielding( cgmr, cgmr.execute() );
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
        response = yield channel.enqueueAsyncYielding( cgmm, cgmm.execute() );
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
        response = yield channel.enqueueAsyncYielding( cgmi, cgmi.execute() );
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
        response = yield channel.enqueueAsyncYielding( cgsn, cgsn.execute() );
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
        response = yield channel.enqueueAsyncYielding( cmickey, cmickey.execute() );
        if ( cmickey.validate( response ) == AtResponse.VALID )
        {
            value = (string) cmickey.value;
            info.insert( "mickey", value );
        }
    }
}

/**
 * Get device features.
 **/
public class AtDeviceGetFeatures : DeviceGetFeatures
{
    public override async void run() throws FreeSmartphone.Error
    {
        features = new GLib.HashTable<string,Value?>( str_hash, str_equal );
        var channel = theModem.channel( "main" );
        var value = Value( typeof(string) );

        var gcap = theModem.createAtCommand<PlusGCAP>( "+GCAP" );
        var response = yield channel.enqueueAsyncYielding( gcap, gcap.execute() );
        gcap.parse( response[0] );

        if ( "GSM" in gcap.value )
        {
            value = (string) "TA";
            features.insert( "gsm", value );
        }

        var cgclass = theModem.createAtCommand<PlusCGCLASS>( "+CGCLASS" );
        response = yield channel.enqueueAsyncYielding( cgclass, cgclass.test() );
        cgclass.parseTest( response[0] );
        value = (string) cgclass.righthandside;
        features.insert( "gprs", value );

        var fclass = theModem.createAtCommand<PlusFCLASS>( "+FCLASS" );
        response = yield channel.enqueueAsyncYielding( fclass, fclass.test() );
        fclass.parse( response[0] );
        value = (string) fclass.faxclass;
        features.insert( "fax", value );
    }
}

/**
 * List providers.
 **/
public class AtNetworkListProviders : NetworkListProviders
{
    public override async void run() throws FreeSmartphone.Error
    {
        var channel = theModem.channel( "main" );

        var cops = theModem.createAtCommand<PlusCOPS_Test>( "+COPS=?" );
        var response = yield channel.enqueueAsyncYielding( cops, cops.issue() );
        cops.parse( response[0] );
        providers = cops.providerList();
    }
}

public class AtDeviceGetMicrophoneMuted : DeviceGetMicrophoneMuted
{
    public override async void run() throws FreeSmartphone.Error
    {
        var channel = theModem.channel( "main" );

        var cmd = theModem.createAtCommand<PlusCMUT>( "+CMUT" );
        var response = yield channel.enqueueAsyncYielding( cmd, cmd.query() );

        checkResponseValid( cmd, response );
        muted = cmd.value == 1;
    }
}

public class AtDeviceGetSpeakerVolume : DeviceGetSpeakerVolume
{
    public override async void run() throws FreeSmartphone.Error
    {
        yield gatherSpeakerVolumeRange();

        var channel = theModem.channel( "main" );

        var cmd = theModem.createAtCommand<PlusCLVL>( "+CLVL" );
        var response = yield channel.enqueueAsyncYielding( cmd, cmd.query() );
        checkResponseValid( cmd, response );

        var data = theModem.data();
        volume = data.speakerVolumeMinimum + cmd.value * 100 / ( data.speakerVolumeMaximum - data.speakerVolumeMinimum );
    }
}

public class AtDeviceGetPowerStatus : DeviceGetPowerStatus
{
    public override async void run() throws FreeSmartphone.Error
    {
        var channel = theModem.channel( "main" );

        var cmd = theModem.createAtCommand<PlusCBC>( "+CBC" );
        var response = yield channel.enqueueAsyncYielding( cmd, cmd.execute() );

        checkResponseValid( cmd, response );
        status = cmd.status;
        level = cmd.level;
    }
}

public class AtDeviceSetMicrophoneMuted : DeviceSetMicrophoneMuted
{
    public override async void run( bool muted ) throws FreeSmartphone.Error
    {
        var channel = theModem.channel( "main" );

        var cmut = theModem.createAtCommand<PlusCMUT>( "+CMUT" );
        var response = yield channel.enqueueAsyncYielding( cmut, cmut.issue( muted ? 1 : 0 ) );

        checkResponseOk( cmut, response );
    }
}

public class AtDeviceSetSpeakerVolume : DeviceSetSpeakerVolume
{
    public override async void run( int volume ) throws FreeSmartphone.Error
    {
        if ( volume < 0 || volume > 100 )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Volume needs to be a percentage (0-100)" );
        }

        yield gatherSpeakerVolumeRange();

        var data = theModem.data();
        var value = data.speakerVolumeMinimum + volume * ( data.speakerVolumeMaximum - data.speakerVolumeMinimum ) / 100;

        var channel = theModem.channel( "main" );
        var clvl = theModem.createAtCommand<PlusCLVL>( "+CLVL" );
        var response = yield channel.enqueueAsyncYielding( clvl, clvl.issue( value ) );
        checkResponseOk( clvl, response );
    }
}

public void registerGenericAtMediators( HashMap<Type,Type> table )
{
    // register commands
    table[ typeof(DeviceGetAntennaPower) ]        = typeof( AtDeviceGetAntennaPower );
    table[ typeof(DeviceGetInformation) ]         = typeof( AtDeviceGetInformation );
    table[ typeof(DeviceGetFeatures) ]            = typeof( AtDeviceGetFeatures );
    table[ typeof(DeviceGetMicrophoneMuted) ]     = typeof( AtDeviceGetMicrophoneMuted );
    table[ typeof(DeviceGetSpeakerVolume) ]       = typeof( AtDeviceGetSpeakerVolume );
    table[ typeof(DeviceGetPowerStatus) ]         = typeof( AtDeviceGetPowerStatus );
    table[ typeof(DeviceSetMicrophoneMuted) ]     = typeof( AtDeviceSetMicrophoneMuted );
    table[ typeof(DeviceSetSpeakerVolume) ]       = typeof( AtDeviceSetSpeakerVolume );

    table[ typeof(NetworkListProviders) ]         = typeof( AtNetworkListProviders );
}

} // namespace FsoGsm
