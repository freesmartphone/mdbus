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

using Gee;
using FsoGsm;

/**
 * Public helpers
 **/
public void updateMsmSimAuthStatus( FreeSmartphone.GSM.SIMAuthStatus status )
{
    theModem.logger.info( @"SIM Auth status now $status" );
    
    // send the dbus signal
    var obj = theModem.theDevice<FreeSmartphone.GSM.SIM>();
    obj.auth_status( status );

    // check whether we need to advance the modem state
    var data = theModem.data();
    if ( status != data.simAuthStatus )
    {
        data.simAuthStatus = status;

        // advance global modem state
        var modemStatus = theModem.status();
        if ( modemStatus == Modem.Status.INITIALIZING )
        {
            if ( status == FreeSmartphone.GSM.SIMAuthStatus.READY )
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

/**
 * Debug mediators
 **/

public class MsmDebugPing : DebugPing
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = new Msmcomm.Command.TestAlive();
        var channel = theModem.channel( "main" ) as MsmChannel;
        yield channel.enqueueAsync( (owned) cmd );
    }
}

public class MsmDeviceGetFunctionality : DeviceGetFunctionality
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        #if 0
        var cfun = theModem.createAtCommand<PlusCFUN>( "+CFUN" );
        var response = yield theModem.processAtCommandAsync( cfun, cfun.query() );
        checkResponseValid( cfun, response );
        level = Constants.instance().deviceFunctionalityStatusToString( cfun.value );
        autoregister = theModem.data().keepRegistration;
        pin = theModem.data().simPin;
        #endif
    }
}

public class MsmDeviceGetFeatures : DeviceGetFeatures
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        features = new GLib.HashTable<string,Value?>( str_hash, str_equal );
        
        // NOTE there is actually no command to get all the features
        // from the modem itself; in some responses or urcs are some of
        // this information included. We have to gather them while 
        // handling this response and urcs and update the modem data
        // structure accordingly.

        // prefill results with what the modem claims
        var data = theModem.data();
        features.insert( "gsm", data.supportsGSM );
        features.insert( "voice", data.supportsVoice );
        features.insert( "cdma", data.supportsCDMA );
        features.insert( "csd", data.supportsCSD );
        features.insert( "fax", data.supportsFAX );    
        features.insert( "pgp", data.supportsPDP );
    }
}

public class MsmDeviceGetInformation : DeviceGetInformation
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var channel = theModem.channel( "main" ) as MsmChannel;
        info = new GLib.HashTable<string,Value?>( str_hash, str_equal );

        info.insert( "model", "Palm Pre (Plus)" );
        info.insert( "manufacturer", "Palm, Inc." );

        var cmd = new Msmcomm.Command.GetFirmwareInfo();
        unowned Msmcomm.Reply.GetFirmwareInfo response = (Msmcomm.Reply.GetFirmwareInfo) ( yield channel.enqueueAsync( (owned) cmd ) );
        info.insert( "revision", response.info );

        var cmd2 = new Msmcomm.Command.GetImei();
        unowned Msmcomm.Reply.GetImei response2 = (Msmcomm.Reply.GetImei) ( yield channel.enqueueAsync( (owned) cmd2 ) );
        info.insert( "imei", response2.imei );
    }
}

public class MsmDeviceGetPowerStatus : DeviceGetPowerStatus
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented on MSM" );
    }
}

public class MsmDeviceSetFunctionality : DeviceSetFunctionality
{
    public override async void run( string level, bool autoregister, string pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var operation_mode = Msmcomm.OperationMode.OFFLINE;
        
        switch ( level )
        {
            case "minimal":
            case "full":
                operation_mode = Msmcomm.OperationMode.ONLINE;
                break;
            case "airplane":
                operation_mode = Msmcomm.OperationMode.OFFLINE;
                break;
            default:
                throw new FreeSmartphone.Error.INVALID_PARAMETER( "Functionality needs to be one of \"minimal\", \"airplane\", or \"full\"." );
        }

        var cmd = new Msmcomm.Command.ChangeOperationMode();
        cmd.setOperationMode( operation_mode );
        var channel = theModem.channel( "main" ) as MsmChannel;

        unowned Msmcomm.Message response = yield channel.enqueueAsync( (owned)cmd );
        
        // FIXME update modem status!
    }
}

/**
 * SIM Mediators
 **/

public class MsmSimGetAuthStatus : SimGetAuthStatus
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    { 
        // NOTE: there is no command to gather the actual SIM auth status
        // we have to remember the last state and set it to the right value
        // whenever a command/response needs a modified sim auth state
        var data = theModem.data();
        status = data.simAuthStatus;
    }
}

public class MsmSimGetInformation : SimGetInformation
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        info = new GLib.HashTable<string,Value?>( str_hash, str_equal );
        var value = Value( typeof(string) );
        
        var channel = theModem.channel( "main" ) as MsmChannel;
        
        // FIXME: need some more work as msmcommd reports:
        // 2010-08-06T19:14:17.432180Z [ERROR] msmcommd : processIncommingData: Could not unpack valid frame! crc error?
        // when recieving the SimInfo response and no result is returned via dbus
        
        // 
        // Gather MSISDN from modem
        //
        
        var cmd = new Msmcomm.Command.SimInfo();
        cmd.field_type = Msmcomm.SimInfoFieldType.MSISDN;
        unowned Msmcomm.Reply.Sim response = (Msmcomm.Reply.Sim) (yield channel.enqueueAsync( (owned)cmd ));
    
        if ( response.field_data != null )
        {
            value = @"$( response.field_data )";
            info.insert( "msisdn", value );
        }
        else
        {
            info.insert( "msisdn", "unknown" );
        }
        
        // 
        // Gather IMSI from modem
        //
        
        var cmd1 = new Msmcomm.Command.SimInfo();
        cmd1.field_type = Msmcomm.SimInfoFieldType.IMSI;
        response = (Msmcomm.Reply.Sim) (yield channel.enqueueAsync( (owned)cmd1 ));
    
        if ( response.field_data != null)
        { 
            value = @"$(response.field_data)";
            info.insert( "imsi", value ); 
        }
        else
        {
            info.insert( "imsi", "unknown" );
        }
    }
}

public class MsmSimGetAuthCodeRequired : SimGetAuthCodeRequired
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        required = true;
        
        if (MsmData.instance.pin1_status == MsmData.SimPinStatus.DISABLED &&
            MsmData.instance.pin2_status == MsmData.SimPinStatus.DISABLED)
        {
            required = false;
        }
    }
}

public class MsmSimSendAuthCode : SimSendAuthCode
{
    public override async void run( string pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = new Msmcomm.Command.VerifyPin();
        cmd.pin = pin;
        var channel = theModem.channel( "main" ) as MsmChannel;
        unowned Msmcomm.Message response = yield channel.enqueueAsync( (owned) cmd );
        
        if (response.result != Msmcomm.ResultType.OK)
        {
            throw new FreeSmartphone.GSM.Error.SIM_AUTH_FAILED( @"PIN $pin not accepted" );
        }
    }
}

public class MsmSimDeleteEntry : SimDeleteEntry
{
    public override async void run( string category, int index ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        #if 0
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
        #endif
    }
}

public class MsmSimDeleteMessage : SimDeleteMessage
{
    public override async void run( int index ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        #if 0
        var cmd = theModem.createAtCommand<PlusCMGD>( "+CMGD" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( index ) );
        checkResponseExpected( cmd, response, {
            Constants.AtResponse.OK,
            Constants.AtResponse.CMS_ERROR_321_INVALID_MEMORY_INDEX
        } );
        //FIXME: theModem.smshandler.resync();
        #endif
    }
}

public class MsmSimGetPhonebookInfo : SimGetPhonebookInfo
{
    public override async void run( string category, out int slots, out int numberlength, out int namelength ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        #if 0
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
        #endif
    }
}

public class MsmSimGetServiceCenterNumber : SimGetServiceCenterNumber
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        #if 0
        var cmd = theModem.createAtCommand<PlusCSCA>( "+CSCA" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.query() );
        checkResponseValid( cmd, response );
        number = cmd.number;
        #endif
    }
}

public class MsmSimGetUnlockCounters : SimGetUnlockCounters
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }
}

public class MsmSimRetrieveMessage : SimRetrieveMessage
{
    public override async void run( int index, out string status, out string number, out string contents, out GLib.HashTable<string,GLib.Value?> properties ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        #if 0
        properties = new GLib.HashTable<string,Value?>( str_hash, str_equal );

        var cmgr = theModem.createAtCommand<PlusCMGR>( "+CMGR" );
        var response = yield theModem.processAtCommandAsync( cmgr, cmgr.issue( index ) );
        checkMultiResponseValid( cmgr, response );

        var sms = Sms.Message.newFromHexPdu( cmgr.hexpdu, cmgr.tpdulen );
        status = Constants.instance().simMessagebookStatusToString( cmgr.status );
        number = sms.number();
        contents = sms.to_string();
        properties = sms.properties();
        #endif
    }
}

public class MsmSimRetrievePhonebook : SimRetrievePhonebook
{
    public override async void run( string category, int mindex, int maxdex ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        #if 0
        var cat = Constants.instance().simPhonebookStringToCode( category );
        if ( cat == "" )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Invalid Category" );
        }

        phonebook = theModem.pbhandler.storage.phonebook( cat, mindex, maxdex );
        
        #endif
    }
}

public class MsmSimSendStoredMessage : SimSendStoredMessage
{
    public override async void run( int index ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        #if 0
        var cmd = theModem.createAtCommand<PlusCMSS>( "+CMSS" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( index ) );
        checkResponseValid( cmd, response );
        transaction_index = cmd.refnum;

        //FIXME: What should we do with that?
        timestamp = "now";
        #endif
    }
}

public class MsmSimSetServiceCenterNumber : SimSetServiceCenterNumber
{
    public override async void run( string number ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        #if 0
        validatePhoneNumber( number );
        var cmd = theModem.createAtCommand<PlusCSCA>( "+CSCA" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( number ) );
        checkResponseOk( cmd, response );
        #endif
    }
}

public class MsmSimStoreMessage : SimStoreMessage
{
    public override async void run( string recipient_number, string contents, bool want_report ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        #if 0
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
        
        #endif
    }
}

public class MsmSimUnlock : SimUnlock
{
    public override async void run( string puk, string newpin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        #if 0
        var cmd = theModem.createAtCommand<PlusCPIN>( "+CPIN" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( puk, newpin ) );
        checkResponseOk( cmd, response );
        #endif
    }
}

public class MsmSimWriteEntry : SimWriteEntry
{
    public override async void run( string category, int index, string number, string name ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        #if 0
        var cat = Constants.instance().simPhonebookStringToCode( category );
        if ( cat == "" )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Invalid category" );
        }

        var cmd = theModem.createAtCommand<PlusCPBW>( "+CPBW" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( cat, index, number, name ) );
        checkResponseOk( cmd, response );
        #endif
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
        unowned Msmcomm.Message response = yield channel.enqueueAsync( (owned) cmd );
    }
}

/**
 * Call Mediators
 **/
public class MsmCallActivate : CallActivate
{
    public override async void run( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented on MSM" );
//~         yield theModem.callhandler.activate( id );
    }
}

public class MsmCallHoldActive : CallHoldActive
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented on MSM" );
//~         yield theModem.callhandler.hold();
    }
}

public class MsmCallInitiate : CallInitiate
{
    public override async void run( string number, string ctype ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented on MSM" );
//~         validatePhoneNumber( number );
//~         id = yield theModem.callhandler.initiate( number, ctype );
    }
}

public class MsmCallListCalls : CallListCalls
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented on MSM" );
//~         var cmd = theModem.createAtCommand<PlusCLCC>( "+CLCC" );
//~         var response = yield theModem.processAtCommandAsync( cmd, cmd.execute() );
//~         checkMultiResponseValid( cmd, response );
//~         calls = cmd.calls;
    }
}

public class MsmCallSendDtmf : CallSendDtmf
{
    public override async void run( string tones ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented on MSM" );
//~         var cmd = theModem.createAtCommand<PlusVTS>( "+VTS" );
//~         var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( tones ) );
//~         checkResponseOk( cmd, response );
    }
}

public class MsmCallRelease : CallRelease
{
    public override async void run( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented on MSM" );
//~         yield theModem.callhandler.release( id );
    }
}

public class MsmCallReleaseAll : CallReleaseAll
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented on MSM" );
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

    table[ typeof(DeviceGetFeatures) ]            = typeof( MsmDeviceGetFeatures );
    table[ typeof(DeviceGetInformation) ]         = typeof( MsmDeviceGetInformation );
    table[ typeof(DeviceGetFunctionality) ]       = typeof( MsmDeviceGetFunctionality );
    table[ typeof(DeviceGetPowerStatus) ]         = typeof( MsmDeviceGetPowerStatus );
    table[ typeof(DeviceSetFunctionality) ]       = typeof( MsmDeviceSetFunctionality );

    table[ typeof(SimGetAuthCodeRequired) ]       = typeof( MsmSimGetAuthCodeRequired );
    table[ typeof(SimGetAuthStatus) ]             = typeof( MsmSimGetAuthStatus );
    table[ typeof(SimGetInformation) ]            = typeof( MsmSimGetInformation );
    table[ typeof(SimSendAuthCode) ]              = typeof( MsmSimSendAuthCode );
    table[ typeof(SimDeleteEntry) ]               = typeof( MsmSimDeleteEntry );
    table[ typeof(SimDeleteMessage) ]             = typeof( MsmSimDeleteMessage );
    table[ typeof(SimGetPhonebookInfo) ]          = typeof( MsmSimGetPhonebookInfo );
    table[ typeof(SimGetServiceCenterNumber) ]    = typeof( MsmSimGetServiceCenterNumber );
    table[ typeof(SimGetUnlockCounters) ]         = typeof( MsmSimGetUnlockCounters );
    table[ typeof(SimRetrieveMessage) ]           = typeof( MsmSimRetrieveMessage );
    table[ typeof(SimRetrievePhonebook) ]         = typeof( MsmSimRetrievePhonebook );
    table[ typeof(SimSendStoredMessage) ]         = typeof( MsmSimSendStoredMessage );
    table[ typeof(SimSetServiceCenterNumber) ]    = typeof( MsmSimSetServiceCenterNumber );
    table[ typeof(SimStoreMessage) ]              = typeof( MsmSimStoreMessage );
    table[ typeof(SimWriteEntry) ]                = typeof( MsmSimWriteEntry );

    table[ typeof(NetworkRegister) ]              = typeof( MsmNetworkRegister );

    table[ typeof(CallActivate) ]                 = typeof( MsmCallActivate );
    table[ typeof(CallHoldActive) ]               = typeof( MsmCallHoldActive );
    table[ typeof(CallInitiate) ]                 = typeof( MsmCallInitiate );
    table[ typeof(CallListCalls) ]                = typeof( MsmCallListCalls );
    table[ typeof(CallReleaseAll) ]               = typeof( MsmCallReleaseAll );
    table[ typeof(CallRelease) ]                  = typeof( MsmCallRelease );
    table[ typeof(CallSendDtmf) ]                 = typeof( MsmCallSendDtmf );
}
