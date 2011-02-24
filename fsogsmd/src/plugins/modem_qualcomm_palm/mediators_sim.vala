/*
 * Copyright (C) 2010-2011 Simon Busch <morphis@gravedo.de>
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

using FsoGsm;
using Msmcomm;

private PhonebookBookType categoryToBookType( string category )
{
    var result = PhonebookBookType.ADN;

    switch ( category )
    {
        case "contacts":
            result = PhonebookBookType.ADN;
            break;
        //case "emergency":
            // result = PhonebookBookType.EFECC;
            //break;
        case "aux:fixed":
            result = PhonebookBookType.FDN;
            break;
    }

    return result;
}

private string bookTypeToCategory( PhonebookBookType book_type)
{
    string result = "unknown";

    switch ( book_type )
    {
        case PhonebookBookType.ADN:
            result = "contacts";
            break;
        case PhonebookBookType.FDN:
            result = "aux:fixed";
            break;
#if 0
        case PhonebookBookType.EFECC:
            result = "emergency";
            break;
#endif
    }

    return result;
}

public class MsmSimChangeAuthCode : SimChangeAuthCode
{
    public override async void run( string oldpin, string newpin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.UNSUPPORTED( "Not yet implemented!" );
    }
}

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
        info = new GLib.HashTable<string,Variant>( str_hash, str_equal );
        var channel = theModem.channel( "main" ) as MsmChannel;

        try
        {
            SimFieldInfo fi = yield channel.sim_service.read( SimFieldType.MSISDN );
            info.insert( "msisdn", fi.data );

            fi = yield channel.sim_service.read( SimFieldType.IMSI );
            info.insert( "imsi", fi.data );

            info.insert( "phonebooks", "contacts emergency aux:fixed" );
        }
        catch ( Msmcomm.Error err0 )
        {
            var msg = @"Could not process SIM read command, got: $(err0.message)";
            throw new FreeSmartphone.Error.INTERNAL_ERROR( msg );
        }
        catch ( GLib.Error err1 )
        {
        }
    }
}

public class MsmSimGetAuthCodeRequired : SimGetAuthCodeRequired
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        required = true;

        if ( MsmData.pin_status == MsmPinStatus.DISABLED )
        {
            required = false;
        }
    }
}

public class MsmSimSendAuthCode : SimSendAuthCode
{
    public override async void run( string pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var channel = theModem.channel( "main" ) as MsmChannel;

        try
        {
            // We only send the verify_pin command to the modem when the pin is enabled.
            // When not we return an error.
            if ( MsmData.pin_status == MsmPinStatus.ENABLED )
            {
                yield channel.sim_service.verify_pin( Msmcomm.SimPinType.PIN1, pin );
            }
            else
            {
                throw new FreeSmartphone.GSM.Error.SIM_AUTH_FAILED( @"Could not send auth code as auth code is disabled" );
            }
        }
        catch ( Msmcomm.Error err0 )
        {
            var msg = @"Could not process verify_pin command, got: $(err0.message)";
            throw new FreeSmartphone.Error.INTERNAL_ERROR( msg );
        }
        catch ( GLib.Error err1 )
        {
        }
    }
}

public class MsmSimDeleteEntry : SimDeleteEntry
{
    public override async void run( string category, int index ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var channel = theModem.channel( "main" ) as MsmChannel;
        try
        {
            var book_type = categoryToBookType( category );
            // As there is no real delete command for the phonebook we overwrite  with an emtpy
            // number and title the old record
            yield channel.phonebook_service.write_record( book_type, (uint) index, "", "" );

            // Resync complete phonebook
            var pbhandler = theModem.pbhandler as MsmPhonebookHandler;
            pbhandler.syncPhonebook( book_type );
        }
        catch ( Msmcomm.Error err0 )
        {
            var msg = @"Could not process the write_record command, got: $(err0.message)";
            throw new FreeSmartphone.Error.INTERNAL_ERROR( msg );
        }
        catch ( GLib.Error err1 )
        {
        }
    }
}

public class MsmSimGetPhonebookInfo : SimGetPhonebookInfo
{
    private async void retrievePhonebookProperties( PhonebookBookType book_type )
    {
        try
        {
            var channel = theModem.channel( "main" ) as MsmChannel;
            yield channel.phonebook_service.extended_file_info( book_type );
        }
        catch ( Msmcomm.Error err0 )
        {
        }
        catch ( GLib.Error err1 )
        {
        }
    }

    public override async void run( string category, out int slots, out int numberlength, out int namelength ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var channel = theModem.channel( "main" ) as MsmChannel;
        try
        {
            var book_type = categoryToBookType( category );

            // Retrieve phonebook properties but don't care about the result; Will timeout
            // as we get the correct result with an unsolicited response.
            Idle.add( () => { retrievePhonebookProperties( book_type ); return false; });

            var info = (yield channel.urc_handler.waitForUnsolicitedResponse( MsmUrcType.EXTENDED_FILE_INFO )) as PhonebookInfo;

            slots = (int) info.slot_count;
            numberlength = (int) info.max_chars_per_number;
            namelength = (int) info.max_chars_per_title;
        }
        catch ( Msmcomm.Error err0 )
        {
            var msg = @"Could not process get_phonebook_properties command, got: $(err0.message)";
            throw new FreeSmartphone.Error.INTERNAL_ERROR( msg );
        }
        catch ( GLib.Error err1 )
        {
        }
    }
}

public class MsmSimRetrievePhonebook : SimRetrievePhonebook
{
    public override async void run( string category, int mindex, int maxdex ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        phonebook = theModem.pbhandler.storage.phonebook( category, mindex, maxdex );
    }
}

public class MsmSimWriteEntry : SimWriteEntry
{
    public override async void run( string category, int index, string number, string name ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var channel = theModem.channel( "main" ) as MsmChannel;
        try
        {
            var book_type = categoryToBookType( category );
            yield channel.phonebook_service.write_record( book_type, (uint) index, name, number );

            // Resync complete phonebook
            var pbhandler = theModem.pbhandler as MsmPhonebookHandler;
            pbhandler.syncPhonebook( book_type );

        }
        catch ( Msmcomm.Error err0 )
        {
            var msg = @"Could not process write_record command, got: $(err0.message)";
            throw new FreeSmartphone.Error.INTERNAL_ERROR( msg );
        }
        catch ( GLib.Error err1 )
        {
        }
    }
}

public class MsmSimDeleteMessage : SimDeleteMessage
{
    public override async void run( int index ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.UNSUPPORTED( "Not yet implemented" );
    }
}


public class MsmSimGetServiceCenterNumber : SimGetServiceCenterNumber
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.UNSUPPORTED( "Not yet implemented" );
    }
}

public class MsmSimGetUnlockCounters : SimGetUnlockCounters
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.UNSUPPORTED( "Not yet implemented" );
    }
}

public class MsmSimRetrieveMessage : SimRetrieveMessage
{
    public override async void run( int index, out string status, out string number, out string contents, out GLib.HashTable<string,GLib.Variant> properties ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
       throw new FreeSmartphone.Error.UNSUPPORTED( "Not yet implemented" );
    }
}

public class MsmSimSendStoredMessage : SimSendStoredMessage
{
    public override async void run( int index ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.UNSUPPORTED( "Not yet implemented" );
    }
}

public class MsmSimSetServiceCenterNumber : SimSetServiceCenterNumber
{
    public override async void run( string number ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.UNSUPPORTED( "Not yet implemented" );
    }
}

public class MsmSimStoreMessage : SimStoreMessage
{
    public override async void run( string recipient_number, string contents, bool want_report ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.UNSUPPORTED( "Not yet implemented" );
    }
}

public class MsmSimUnlock : SimUnlock
{
    public override async void run( string puk, string newpin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.UNSUPPORTED( "Not yet implemented" );
    }
}

