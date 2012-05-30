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
        var cat = Constants.simPhonebookStringToCode( category );
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

        yield theModem.pbhandler.syncWithSim();
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
                Constants.simFilesystemEntryNameToCode( "EFspn" ), 0, 0, 17 ) );
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
                Constants.simFilesystemEntryNameToCode( "EF_SPN_CPHS" ), 0, 0, 10 ) );
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
                pbnames += Constants.simPhonebookCodeToString( pbcode );
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
        var cat = Constants.simPhonebookStringToCode( category );
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
        if ( sms == null )
        {
            throw new FreeSmartphone.GSM.Error.DEVICE_FAILED( @"Can't read SMS at index $index" );
        }

        status = Constants.simMessagebookStatusToString( cmgr.status );
        number = sms.number();
        contents = sms.to_string();
        properties = sms.properties();
    }
}

public class AtSimRetrievePhonebook : SimRetrievePhonebook
{
    public override async void run( string category, int mindex, int maxdex ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cat = Constants.simPhonebookStringToCode( category );
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
        var cat = Constants.simPhonebookStringToCode( category );
        if ( cat == "" )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Invalid category" );
        }

        var cmd = theModem.createAtCommand<PlusCPBW>( "+CPBW" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( cat, index, number, name ) );
        checkResponseOk( cmd, response );
    }
}

} // namespace FsoGsm

// vim:ts=4:sw=4:expandtab
