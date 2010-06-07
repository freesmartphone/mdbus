/*
 * Copyright (C) 2010  Antonio Ospite <ospite@studenti.unina.it>
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

using FsoGsm;
using Gee;

namespace FreescaleNeptune {

/**
 * Debug mediators
 **/

/**
 * Modem not implementing any of +CGMR;+CGMM;+CGMI -- only +CGSN is supported
 **/
public class NeptuneDeviceGetInformation : DeviceGetInformation
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        /*
        var channel = theModem.channel( "main" ) as AtChannel;
        */
        info = new GLib.HashTable<string,Value?>( str_hash, str_equal );

        info.insert( "manufacturer", "Motorola" );
        info.insert( "model", "Neptune Freescale Modem" );

        /* FIXME: Use information from the +EBPV URC we get on modem init */
        info.insert( "revision", "unknown" );

        /* "+CGSN" */
        var cgsn = theModem.createAtCommand<PlusCGSN>( "+CGSN" );
        var response = yield theModem.processAtCommandAsync( cgsn, cgsn.query() );
        checkResponseValid( cgsn, response );
        info.insert( "imei", cgsn.value );
    }
}


/**
 * SIM Mediators
 **/

/**
 * Modem violating GSM 07.07 here.
 *
 * Format seems to be +CPIN=<number>,"<PIN>", where 1 is PIN1, 2 may be PIN2 or PUK1
 **/
public class NeptuneSimSendAuthCode : SimSendAuthCode
{
    public override async void run( string pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<NeptunePlusCPIN>( "+CPIN" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( 1, pin ) );
        var code = checkResponseExpected( cmd, response,
            { Constants.AtResponse.OK, Constants.AtResponse.CME_ERROR_016_INCORRECT_PASSWORD } );

        if ( code == Constants.AtResponse.CME_ERROR_016_INCORRECT_PASSWORD )
        {
            throw new FreeSmartphone.GSM.Error.SIM_AUTH_FAILED( @"PIN $pin not accepted" );
        }

        gatherSimStatusAndUpdate();
    }
}


/**
 * SMS Mediators
 **/

/**
 * Network Mediators
 **/

public class NeptuneNetworkRegister : NetworkRegister
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        // FIXME: find a better way to make NetworkRegister reliable,
        // avoid sleeping if possible.
        Thread.usleep(4000 * 1000);
        var cmd = theModem.createAtCommand<PlusCOPS>( "+COPS" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( PlusCOPS.Action.REGISTER_WITH_BEST_PROVIDER ) );
        checkResponseOk( cmd, response );
    }
}

public class NeptuneNetworkUnregister : NetworkUnregister
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusCOPS>( "+COPS" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( PlusCOPS.Action.UNREGISTER ) );
        // FIXME: find a better way to make NetworkRegister reliable,
        // avoid sleeping if possible.
        Thread.usleep(4000 * 1000);
        checkResponseOk( cmd, response );
    }
}

/**
 * Call Mediators
 **/

/**
 * Neptune replies to +CLCC? but not to +CLCC
 * So we use cmd.query() here instead of cmd.execute()
 **/
public class NeptuneCallListCalls : CallListCalls
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusCLCC>( "+CLCC" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.query() );
        checkMultiResponseValid( cmd, response );
        calls = cmd.calls;
    }
}

/**
 * PDP Mediators
 **/

/**
 * Register all mediators
 **/
public void registerNeptuneMediators( HashMap<Type,Type> table )
{
    /*
    table[ typeof(DebugPing) ]                    = typeof( NeptuneDebugPing );
    */

    table[ typeof(DeviceGetInformation) ]         = typeof( NeptuneDeviceGetInformation );
    table[ typeof(SimSendAuthCode) ]              = typeof( NeptuneSimSendAuthCode );

    table[ typeof(NetworkRegister) ]              = typeof( NeptuneNetworkRegister );
    table[ typeof(NetworkUnregister) ]            = typeof( NeptuneNetworkUnregister );

    table[ typeof(CallListCalls) ]                = typeof( NeptuneCallListCalls );
}

} /* FreescaleNeptune */
