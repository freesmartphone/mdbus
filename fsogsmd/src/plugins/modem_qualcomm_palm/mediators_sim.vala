/*
 * Copyright (C) 2010 Simon Busch <morphis@gravedo.de>
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

