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
        try
        {
            var cmds = MsmModemAgent.instance().commands;
            yield cmds.test_alive();
        }
        catch ( Msmcomm.Error err0 )
        {
            var msg = @"Could not process test_alive command, got: $(err0.message)";
            throw new FreeSmartphone.Error.INTERNAL_ERROR( msg );
        }
        catch ( DBus.Error err1 )
        {
        }
    }
}

/**
 * Device mediators
 **/

public class MsmDeviceGetFunctionality : DeviceGetFunctionality
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        // NOTE: We currently cannot get the functionality status directly
        // from the modem, so we have to save it statically and switch it
        // whenever we need
        level = Msmcomm.deviceFunctionalityStatusToString( Msmcomm.RuntimeData.functionality_status );
        
        autoregister = theModem.data().keepRegistration;
        pin = theModem.data().simPin;
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
        features.insert( "pdp", data.supportsPDP );
    }
}

public class MsmDeviceGetInformation : DeviceGetInformation
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmds = MsmModemAgent.instance().commands;
        
        try
        {
            info = new GLib.HashTable<string,Value?>( str_hash, str_equal );

            info.insert( "model", "Palm Pre (Plus)" );
            info.insert( "manufacturer", "Palm, Inc." );
            
            Msmcomm.FirmwareInfo firmware_info;
            firmware_info = yield cmds.get_firmware_info();
            
            info.insert( "revision", firmware_info.version_string );

            string imei = yield cmds.get_imei();
            info.insert( "imei", imei );
        }
        catch ( Msmcomm.Error err0 )
        {
            var msg = @"Could not process get_firmware_info/get_imei command, got: $(err0.message)";
            throw new FreeSmartphone.Error.INTERNAL_ERROR( msg );
        }
        catch ( DBus.Error err1 )
        {
        }
    }
}

public class MsmDeviceGetPowerStatus : DeviceGetPowerStatus
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        try
        {
            var cmds = MsmModemAgent.instance().commands;
            Msmcomm.ChargerStatus charger_status = yield cmds.get_charger_status();
                
            switch (charger_status.mode)
            {
                case Msmcomm.ChargerStatusMode.USB:
                    status = FreeSmartphone.Device.PowerStatus.AC;
                    break;
                case Msmcomm.ChargerStatusMode.INDUCTIVE:
                    status = FreeSmartphone.Device.PowerStatus.CHARGING;
                    break;
                default:                                                
                    status = FreeSmartphone.Device.PowerStatus.UNKNOWN;
                    break;
            }
            
            // FIXME How can we find about current charging level? need
            // to fix this in msmcomm! As long as we don't know how to
            // retrieve the right value, we report a very low level to 
            // indicate that the user should have a charging status very
            // close as current level is unknown ...
            level = 10;
        }
        catch ( Msmcomm.Error err0 )
        {
            var msg = @"Could not process get_charger_status command, got: $(err0.message)";
            throw new FreeSmartphone.Error.INTERNAL_ERROR( msg );
        }
        catch ( DBus.Error err1 )
        {
        }
    }
}

public class MsmDeviceSetFunctionality : DeviceSetFunctionality
{
    public override async void run( string level, bool autoregister, string pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var operation_mode = "offline";
        
        switch ( level )
        {
            case "minimal":
            case "full":
                Msmcomm.RuntimeData.functionality_status = Msmcomm.ModemOperationMode.ONLINE;
                break;
            case "airplane":
                Msmcomm.RuntimeData.functionality_status = Msmcomm.ModemOperationMode.OFFLINE;
                break;
            default:
                throw new FreeSmartphone.Error.INVALID_PARAMETER( "Functionality needs to be one of \"minimal\", \"airplane\", or \"full\"." );
        }

        try 
        {
            var cmds = MsmModemAgent.instance().commands;
            yield cmds.change_operation_mode( Msmcomm.RuntimeData.functionality_status ); 
        }
        catch ( Msmcomm.Error err0 )
        {
            var msg = @"Could not process change_operation_mode command, got: $(err0.message)";
            throw new FreeSmartphone.Error.INTERNAL_ERROR( msg );
        }
        catch ( DBus.Error err1 )
        {
        }
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
    private void checkAndAddInfo(string name, string value)
    {
        if (value == null)
        {
            info.insert( name, "unknown" );
        }
        else
        {
            info.insert( name, @"$(value)" );
        }
    }
    
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        info = new GLib.HashTable<string,Value?>( str_hash, str_equal );
        var value = Value( typeof(string) );
        
        var cmds = MsmModemAgent.instance().commands;
        
        try 
        {
            string msisdn = yield cmds.sim_info( "msisdn" );
            checkAndAddInfo( "msisdn", msisdn );

            string imsi = yield cmds.sim_info( "imsi" );
            checkAndAddInfo( "imsi", imsi );
        }
        catch ( Msmcomm.Error err0 ) 
        {
            var msg = @"Could not process verify_pin command, got: $(err0.message)";
            throw new FreeSmartphone.Error.INTERNAL_ERROR( msg );
        }
        catch ( DBus.Error err1 )
        {
        }
    }
}

public class MsmSimGetAuthCodeRequired : SimGetAuthCodeRequired
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        required = true;
        
        if (Msmcomm.RuntimeData.pin1_status == Msmcomm.SimPinStatus.DISABLED &&
            Msmcomm.RuntimeData.pin2_status == Msmcomm.SimPinStatus.DISABLED)
        {
            required = false;
        }
    }
}

public class MsmSimSendAuthCode : SimSendAuthCode
{
    public override async void run( string pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmds = MsmModemAgent.instance().commands;
        
        try 
        {
            // FIXME select pin type acording to the current active pin
            yield cmds.verify_pin( "pin1", pin );
        }
        catch ( Msmcomm.Error err0 ) 
        {
            var msg = @"Could not process verify_pin command, got: $(err0.message)";
            throw new FreeSmartphone.Error.INTERNAL_ERROR( msg );
        }
        catch ( DBus.Error err1 )
        {
        }
    }
}

public class MsmSimDeleteEntry : SimDeleteEntry
{
    public override async void run( string category, int index ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        try
        {
            var cmds = MsmModemAgent.instance().commands;
            var bookType = Msmcomm.stringToPhonebookBookType( category );
            
            cmds.delete_phonebook( bookType, (uint) index );
        }
        catch ( Msmcomm.Error err0 )
        {
            var msg = @"Could not process the delete_phonebook command, got: $(err0.message)";
            throw new FreeSmartphone.Error.INTERNAL_ERROR( msg );
        }
        catch ( DBus.Error err1 )
        {
        }
    }
}

public class MsmSimDeleteMessage : SimDeleteMessage
{
    public override async void run( int index ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }
}

public class MsmSimGetPhonebookInfo : SimGetPhonebookInfo
{
    public override async void run( string category, out int slots, out int numberlength, out int namelength ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        try
        {
            var bookType = Msmcomm.stringToPhonebookBookType( category );
            var cmds = MsmModemAgent.instance().commands;

            Msmcomm.PhonebookProperties pbprops = yield cmds.get_phonebook_properties( bookType );
            slots = pbprops.slot_count;
            numberlength = pbprops.max_chars_per_number;
            namelength = pbprops.max_chars_per_title;
        }
        catch ( Msmcomm.Error err0 )
        {
            var msg = @"Could not process get_phonebook_properties command, got: $(err0.message)";
            throw new FreeSmartphone.Error.INTERNAL_ERROR( msg );
        }
        catch ( DBus.Error err1 )
        {
        }

    }
}

public class MsmSimGetServiceCenterNumber : SimGetServiceCenterNumber
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        #if 0
        // FIXME have to implement this when libmsmcomm fully supports the
        // get_service_center_number command which currently does not
        try 
        {
            var cmds = MsmModemAgent.instance().commands;
            
            // We first send the command to get the sms center number and afterwards we
            // have to wait for the right urc which supplies the number of the service
            // center
            yield cmds.get_sms_center_number();
        }
        catch ( Msmcomm.Error err0 )
        {
            var msg = @"Could not process get_phonebook_properties command, got: $(err0.message)";
            throw new FreeSmartphone.Error.INTERNAL_ERROR( msg );
        }
        catch ( DBus.Error err1 )
        {
        }
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
       throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }
}

public class MsmSimRetrievePhonebook : SimRetrievePhonebook
{
    public override async void run( string category, int mindex, int maxdex ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        #if 0
        var cat = Msmcomm.simPhonebookStringToPhonebookType( category );
        if ( cat == Msmcomm.PhonebookType.NONE )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Invalid Category" );
        }
        phonebook = theModem.pbhandler.storage.phonebook( category, mindex, maxdex );
        #endif
    }
}

public class MsmSimSendStoredMessage : SimSendStoredMessage
{
    public override async void run( int index ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }
}

public class MsmSimSetServiceCenterNumber : SimSetServiceCenterNumber
{
    public override async void run( string number ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }
}

public class MsmSimStoreMessage : SimStoreMessage
{
    public override async void run( string recipient_number, string contents, bool want_report ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }
}

public class MsmSimUnlock : SimUnlock
{
    public override async void run( string puk, string newpin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }
}

public class MsmSimWriteEntry : SimWriteEntry
{
    public override async void run( string category, int index, string number, string name ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        try
        {
            var bookType = Msmcomm.stringToPhonebookBookType( category );
            var cmds = MsmModemAgent.instance().commands;
            
            // NOTE Here we can't set the index of the entry to write to the sim card - we
            // get the index of the new entry by the write operation to the sim card.
            // Maybe the API has to be fixed to support index of new entries supplied by
            // the SIM/modem itself and not by the user.
            var new_index = yield cmds.write_phonebook( bookType, number, name );
        }
        catch ( Msmcomm.Error err0 )
        {
            var msg = @"Could not process get_phonebook_properties command, got: $(err0.message)";
            throw new FreeSmartphone.Error.INTERNAL_ERROR( msg );
        }
        catch ( DBus.Error err1 )
        {
        }
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
        #if 0
        var cmd = new Msmcomm.Command.ChangeOperationMode();
        cmd.setOperationMode( Msmcomm.OperationMode.ONLINE );
        var channel = theModem.channel( "main" ) as MsmChannel;
        unowned Msmcomm.Message response = yield channel.enqueueAsync( (owned) cmd );
        #endif
    }
}

public class MsmNetworkGetSignalStrength : NetworkGetSignalStrength
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        signal = Msmcomm.RuntimeData.signal_strength;
    }
}

public class MsmNetworkGetStatus : NetworkGetStatus
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        #if 0
        if ( theModem.data().simIssuer == null )
        {
            var mediator = new AtSimGetInformation();
            yield mediator.run();
        }
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

        bool overrideProviderWithSimIssuer = false;
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
                overrideProviderWithSimIssuer = ( theModem.data().simIssuer != null && creg.status == 1 /* home */ );
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

        // check whether we want to override display name with SIM issuer
        if ( overrideProviderWithSimIssuer )
        {
            status.insert( "display", theModem.data().simIssuer );
        }

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
        #endif
    }
}

public class MsmNetworkListProviders : NetworkListProviders
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        #if 0
        var cmd = theModem.createAtCommand<PlusCOPS>( "+COPS" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.test() );
        checkTestResponseValid( cmd, response );
        providers = cmd.providers;
        #endif
    }
}

public class MsmNetworkUnregister : NetworkUnregister
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        #if 0
        var cmd = theModem.createAtCommand<PlusCOPS>( "+COPS" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( PlusCOPS.Action.UNREGISTER ) );
        checkResponseOk( cmd, response );
        #endif
    }
}

public class MsmNetworkSendUssdRequest : NetworkSendUssdRequest
{
    public override async void run( string request ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        #if 0
        var cmd = theModem.createAtCommand<PlusCUSD>( "+CUSD" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.query( request ) );
        checkResponseOk( cmd, response );
        #endif
    }
}

public class MsmNetworkGetCallingId : NetworkGetCallingId
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        #if 0
        var cmd = theModem.createAtCommand<PlusCLIR>( "+CLIR" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.query() );
        checkResponseValid( cmd, response );
        status = (FreeSmartphone.GSM.CallingIdentificationStatus) cmd.value;
        #endif
    }
}

public class MsmNetworkSetCallingId : NetworkSetCallingId
{
    public override async void run( FreeSmartphone.GSM.CallingIdentificationStatus status ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        #if 0
        var cmd = theModem.createAtCommand<PlusCLIR>( "+CLIR" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( status ) );
        checkResponseOk( cmd, response );
        #endif
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
    table[ typeof(NetworkUnregister) ]            = typeof( MsmNetworkUnregister );
    table[ typeof(NetworkGetSignalStrength) ]     = typeof( MsmNetworkGetSignalStrength );
    table[ typeof(NetworkGetStatus) ]             = typeof( MsmNetworkGetStatus );
    table[ typeof(NetworkListProviders) ]         = typeof( MsmNetworkListProviders );
    table[ typeof(NetworkGetCallingId) ]          = typeof( MsmNetworkGetCallingId );
    table[ typeof(NetworkSendUssdRequest) ]       = typeof( MsmNetworkSendUssdRequest );

    table[ typeof(CallActivate) ]                 = typeof( MsmCallActivate );
    table[ typeof(CallHoldActive) ]               = typeof( MsmCallHoldActive );
    table[ typeof(CallInitiate) ]                 = typeof( MsmCallInitiate );
    table[ typeof(CallListCalls) ]                = typeof( MsmCallListCalls );
    table[ typeof(CallReleaseAll) ]               = typeof( MsmCallReleaseAll );
    table[ typeof(CallRelease) ]                  = typeof( MsmCallRelease );
    table[ typeof(CallSendDtmf) ]                 = typeof( MsmCallSendDtmf );
}
