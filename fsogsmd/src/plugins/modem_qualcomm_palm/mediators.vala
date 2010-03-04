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

/**
 * Debug mediators
 **/

public class MsmDebugPing : DebugPing
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = new Msmcomm.Command.TestAlive();
        var channel = theModem.channel( "main" ) as MsmChannel;
        yield channel.processMsmCommand( cmd );
    }
}

public class MsmDeviceGetFunctionality : DeviceGetFunctionality
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
//~         var cfun = theModem.createAtCommand<PlusCFUN>( "+CFUN" );
//~         var response = yield theModem.processCommandAsync( cfun, cfun.query() );
//~         checkResponseValid( cfun, response );
//~         level = Constants.instance().deviceFunctionalityStatusToString( cfun.value );
//~         autoregister = theModem.data().keepRegistration;
//~         pin = theModem.data().simPin;
    }
}

public class MsmDeviceGetInformation : DeviceGetInformation
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
//~         info = new GLib.HashTable<string,Value?>( str_hash, str_equal );
//~ 
//~         var value = Value( typeof(string) );
//~ 
//~         var cgmr = theModem.createAtCommand<PlusCGMR>( "+CGMR" );
//~         var response = yield theModem.processCommandAsync( cgmr, cgmr.execute() );
//~         if ( cgmr.validate( response ) == Constants.AtResponse.VALID )
//~         {
//~             value = (string) cgmr.value;
//~             info.insert( "revision", value );
//~         }
//~         else
//~         {
//~             info.insert( "revision", "unknown" );
//~         }
//~ 
//~         var cgmm = theModem.createAtCommand<PlusCGMM>( "+CGMM" );
//~         response = yield theModem.processCommandAsync( cgmm, cgmm.execute() );
//~         if ( cgmm.validate( response ) == Constants.AtResponse.VALID )
//~         {
//~             value = (string) cgmm.value;
//~             info.insert( "model", value );
//~         }
//~         else
//~         {
//~             info.insert( "model", "unknown" );
//~         }
//~ 
//~         var cgmi = theModem.createAtCommand<PlusCGMI>( "+CGMI" );
//~         response = yield theModem.processCommandAsync( cgmi, cgmi.execute() );
//~         if ( cgmi.validate( response ) == Constants.AtResponse.VALID )
//~         {
//~             value = (string) cgmi.value;
//~             info.insert( "manufacturer", value );
//~         }
//~         else
//~         {
//~             info.insert( "manufacturer", "unknown" );
//~         }
//~ 
//~         var cgsn = theModem.createAtCommand<PlusCGSN>( "+CGSN" );
//~         response = yield theModem.processCommandAsync( cgsn, cgsn.execute() );
//~         if ( cgsn.validate( response ) == Constants.AtResponse.VALID )
//~         {
//~             value = (string) cgsn.value;
//~             info.insert( "imei", value );
//~         }
//~         else
//~         {
//~             info.insert( "imei", "unknown" );
//~         }
//~ 
//~         var cmickey = theModem.createAtCommand<PlusCMICKEY>( "+CMICKEY" );
//~         response = yield theModem.processCommandAsync( cmickey, cmickey.execute() );
//~         if ( cmickey.validate( response ) == Constants.AtResponse.VALID )
//~         {
//~             value = (string) cmickey.value;
//~             info.insert( "mickey", value );
//~         }
    }
}

public class MsmDeviceGetPowerStatus : DeviceGetPowerStatus
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
//~         var cmd = theModem.createAtCommand<PlusCBC>( "+CBC" );
//~         var response = yield theModem.processCommandAsync( cmd, cmd.execute() );
//~ 
//~         checkResponseValid( cmd, response );
//~         status = cmd.status;
//~         level = cmd.level;
    }
}

public class MsmDeviceSetFunctionality : DeviceSetFunctionality
{
    public override async void run( string level, bool autoregister, string pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var value = Constants.instance().deviceFunctionalityStringToStatus( level );

        if ( value == -1 )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Functionality needs to be one of \"minimal\", \"airplane\", or \"full\"." );
        }

        var cmd = new Msmcomm.Command.ChangeOperationMode();
        cmd.setOperationMode( Msmcomm.OperationMode.RESET );
        var channel = theModem.channel( "main" ) as MsmChannel;

        unowned Msmcomm.Message response = yield channel.processMsmCommand( cmd );
        

//~         var cmd = theModem.createAtCommand<PlusCFUN>( "+CFUN" );
//~         var response = yield theModem.processCommandAsync( cmd, cmd.issue( value ) );
//~         checkResponseExpected( cmd,
//~                          response,
//~                          { Constants.AtResponse.OK, Constants.AtResponse.CME_ERROR_011_SIM_PIN_REQUIRED } );
//~         var data = theModem.data();
//~         data.keepRegistration = autoregister;
//~         data.simPin = pin;
//~ 
//~         yield gatherSimStatusAndUpdate();
    }
}

/**
 * SIM Mediators
 **/
public class MsmSimGetAuthStatus : SimGetAuthStatus
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
//~         var cmd = theModem.createAtCommand<PlusCPIN>( "+CPIN" );
//~         var response = yield theModem.processCommandAsync( cmd, cmd.query() );
//~         checkResponseValid( cmd, response );
//~         status = cmd.status;
    }
}

public class MsmSimGetInformation : SimGetInformation
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
//~         info = new GLib.HashTable<string,Value?>( str_hash, str_equal );
//~ 
//~         var value = Value( typeof(string) );
//~ 
//~         var cimi = theModem.createAtCommand<PlusCGMR>( "+CIMI" );
//~         var response = yield theModem.processCommandAsync( cimi, cimi.execute() );
//~         if ( cimi.validate( response ) == Constants.AtResponse.VALID )
//~         {
//~             value = (string) cimi.value;
//~             info.insert( "imsi", value );
//~         }
//~         else
//~         {
//~             info.insert( "imsi", "unknown" );
//~         }
//~ 
//~         var crsm = theModem.createAtCommand<PlusCRSM>( "+CRSM" );
//~         response = yield theModem.processCommandAsync( crsm, crsm.issue(
//~                 Constants.SimFilesystemCommand.READ_BINARY,
//~                 Constants.instance().simFilesystemEntryNameToCode( "EFspn" ), 0, 0, 17 ) );
//~         if ( crsm.validate( response ) == Constants.AtResponse.VALID )
//~         {
//~             var issuer = Codec.hexToString( crsm.payload );
//~             value = issuer != "" ? issuer : "unknown";
//~             info.insert( "issuer", value );
//~         }
//~         else
//~         {
//~             info.insert( "issuer", "unknown" );
//~         }
//~ 
//~         //FIXME: Add dial_prefix and country
    }
}

public class MsmSimGetAuthCodeRequired : SimGetAuthCodeRequired
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
//~         var cmd = theModem.createAtCommand<PlusCLCK>( "+CLCK" );
//~         var response = yield theModem.processCommandAsync( cmd, cmd.query( "SC" ) );
//~         checkResponseValid( cmd, response );
//~         required = cmd.enabled;
    }
}

public class MsmSimSendAuthCode : SimSendAuthCode
{
    public override async void run( string pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
//~         var cmd = theModem.createAtCommand<PlusCPIN>( "+CPIN" );
//~         var response = yield theModem.processCommandAsync( cmd, cmd.issue( pin ) );
//~         checkResponseOk( cmd, response );
//~         gatherSimStatusAndUpdate();
    }
}


/**
 * SMS Mediators
 **/

/**
 * Network Mediators
 **/

public class MsmNetworkRegister : NetworkRegister
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = new Msmcomm.Command.ChangeOperationMode();
        cmd.setOperationMode( Msmcomm.OperationMode.ONLINE );
        var channel = theModem.channel( "main" ) as MsmChannel;

        unowned Msmcomm.Message response = yield channel.processMsmCommand( (owned) cmd );

//~         var cmd = theModem.createAtCommand<PlusCOPS>( "+COPS" );
//~         var response = yield theModem.processCommandAsync( cmd, cmd.issue( PlusCOPS.Action.REGISTER_WITH_BEST_PROVIDER ) );
//~         checkResponseOk( cmd, response );
    }
}

/**
 * Call Mediators
 **/
public class MsmCallActivate : CallActivate
{
    public override async void run( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
//~         yield theModem.callhandler.activate( id );
    }
}

public class MsmCallHoldActive : CallHoldActive
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
//~         yield theModem.callhandler.hold();
    }
}

public class MsmCallInitiate : CallInitiate
{
    public override async void run( string number, string ctype ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
//~         validatePhoneNumber( number );
//~         id = yield theModem.callhandler.initiate( number, ctype );
    }
}

public class MsmCallListCalls : CallListCalls
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
//~         var cmd = theModem.createAtCommand<PlusCLCC>( "+CLCC" );
//~         var response = yield theModem.processCommandAsync( cmd, cmd.execute() );
//~         checkMultiResponseValid( cmd, response );
//~         calls = cmd.calls;
    }
}

public class MsmCallSendDtmf : CallSendDtmf
{
    public override async void run( string tones ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
//~         var cmd = theModem.createAtCommand<PlusVTS>( "+VTS" );
//~         var response = yield theModem.processCommandAsync( cmd, cmd.issue( tones ) );
//~         checkResponseOk( cmd, response );
    }
}

public class MsmCallRelease : CallRelease
{
    public override async void run( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
//~         yield theModem.callhandler.release( id );
    }
}

public class MsmCallReleaseAll : CallReleaseAll
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
//~         yield theModem.callhandler.releaseAll();
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
    table[ typeof(DebugPing) ]                    = typeof( MsmDebugPing );
    
    table[ typeof(DeviceGetInformation) ]         = typeof( MsmDeviceGetInformation );
    table[ typeof(DeviceGetFunctionality) ]       = typeof( MsmDeviceGetFunctionality );
    table[ typeof(DeviceGetPowerStatus) ]         = typeof( MsmDeviceGetPowerStatus );
    table[ typeof(DeviceSetFunctionality) ]       = typeof( MsmDeviceSetFunctionality );

    table[ typeof(SimGetAuthCodeRequired) ]       = typeof( MsmSimGetAuthCodeRequired );
    table[ typeof(SimGetAuthStatus) ]             = typeof( MsmSimGetAuthStatus );
    table[ typeof(SimGetInformation) ]            = typeof( MsmSimGetInformation );
    table[ typeof(SimSendAuthCode) ]              = typeof( MsmSimSendAuthCode );

    table[ typeof(NetworkRegister) ]              = typeof( MsmNetworkRegister );

    table[ typeof(CallActivate) ]                 = typeof( MsmCallActivate );
    table[ typeof(CallHoldActive) ]               = typeof( MsmCallHoldActive );
    table[ typeof(CallInitiate) ]                 = typeof( MsmCallInitiate );
    table[ typeof(CallListCalls) ]                = typeof( MsmCallListCalls );
    table[ typeof(CallReleaseAll) ]               = typeof( MsmCallReleaseAll );
    table[ typeof(CallRelease) ]                  = typeof( MsmCallRelease );
    table[ typeof(CallSendDtmf) ]                 = typeof( MsmCallSendDtmf );
}

} // namespace FsoGsm
