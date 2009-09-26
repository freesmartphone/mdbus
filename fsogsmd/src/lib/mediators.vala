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

//workaround
using FreeSmartphone.GSM;

namespace FsoGsm {

/**
 * Power on/off the antenna. THIS FUNCTION IS DEPRECATED
 **/
public class AtDeviceGetAntennaPower : DeviceGetAntennaPower
{
    public override async void run() throws FreeSmartphone.Error
    {
        PlusCFUN cfun = theModem.atCommandFactory( "+CFUN" ) as PlusCFUN;
        var channel = theModem.channel( "main" );

        var response = yield channel.enqueueAsyncYielding( cfun, cfun.query() );

        cfun.parse( response[0] );
        antenna_power = cfun.fun == 1;
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

        PlusCGMR cgmr = theModem.atCommandFactory( "+CGMR" ) as PlusCGMR;
        var response = yield channel.enqueueAsyncYielding( cgmr, cgmr.execute() );
        cgmr.parse( response[0] );
        value = (string) cgmr.value;
        info.insert( "revision", value );

        PlusCGMM cgmm = theModem.atCommandFactory( "+CGMM" ) as PlusCGMM;
        response = yield channel.enqueueAsyncYielding( cgmm, cgmm.execute() );
        cgmm.parse( response[0] );
        value = (string) cgmm.value;
        info.insert( "model", value );

        PlusCGMI cgmi = theModem.atCommandFactory( "+CGMI" ) as PlusCGMI;
        response = yield channel.enqueueAsyncYielding( cgmi, cgmi.execute() );
        cgmi.parse( response[0] );
        value = (string) cgmi.value;
        info.insert( "manufacturer", value );

        PlusCGSN cgsn = theModem.atCommandFactory( "+CGSN" ) as PlusCGSN;
        response = yield channel.enqueueAsyncYielding( cgsn, cgsn.execute() );
        cgsn.parse( response[0] );
        value = (string) cgsn.value;
        info.insert( "imei", value );
    }
}

/**
 * List providers.
 **/
public class AtNetworkListProviders : NetworkListProviders
{
    public override async void run() throws FreeSmartphone.Error
    {
        PlusCOPS_Test cops = theModem.atCommandFactory( "+COPS=?" ) as PlusCOPS_Test;
        var channel = theModem.channel( "main" );

        var response = yield channel.enqueueAsyncYielding( cops, cops.issue() );

        cops.parse( response[0] );

        providers = cops.providerList();
    }
}

public void registerGenericAtMediators( HashMap<Type,Type> table )
{
    // register commands
    table[ typeof(DeviceGetAntennaPower) ]        = typeof( AtDeviceGetAntennaPower );
    table[ typeof(DeviceGetInformation) ]         = typeof( AtDeviceGetInformation );

    table[ typeof(NetworkListProviders) ]         = typeof( AtNetworkListProviders );
}

} // namespace FsoGsm
