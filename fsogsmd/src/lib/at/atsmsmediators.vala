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
 * SMS Mediators
 **/
public class AtSmsRetrieveTextMessages : SmsRetrieveTextMessages
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        //FIXME: Bug in Vala
        //messagebook = theModem.smshandler.storage.messagebook();
        //FIXME: Work around
        var array = theModem.smshandler.storage.messagebook();
        messagebook = new FreeSmartphone.GSM.SIMMessage[array.length] {};
        for( int i = 0; i < array.length; ++i )
        {
            messagebook[i] = array[i];
        }
    }
}

public class AtSmsGetSizeForTextMessage : SmsGetSizeForTextMessage
{
    public override async void run( string contents ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var hexpdus = theModem.smshandler.formatTextMessage( "+123456789", contents, false );
        size = hexpdus.size;
    }
}

public class AtSmsSendTextMessage : SmsSendTextMessage
{
    public override async void run( string recipient_number, string contents, bool want_report ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        validatePhoneNumber( recipient_number );

        var hexpdus = theModem.smshandler.formatTextMessage( recipient_number, contents, want_report );

        // signalize that we're sending a couple of SMS
        var cmms = theModem.createAtCommand<PlusCMMS>( "+CMMS" );
        yield theModem.processAtCommandAsync( cmms, cmms.issue( 1 ) ); // not interested in the result

        // send the SMS one after another
        foreach( var hexpdu in hexpdus )
        {
            var cmd = theModem.createAtCommand<PlusCMGS>( "+CMGS" );
            var response = yield theModem.processAtPduCommandAsync( cmd, cmd.issue( hexpdu ) );
            checkResponseValid( cmd, response );
            hexpdu.transaction_index = cmd.refnum;
        }
        transaction_index = theModem.smshandler.lastReferenceNumber();
        //FIXME: What about ACK PDUs?
        timestamp = "now";

        // signalize that we're done
        yield theModem.processAtCommandAsync( cmms, cmms.issue( 0 ) ); // not interested in the result

        // remember transaction indizes for later
        if ( want_report )
        {
            theModem.smshandler.storeTransactionIndizesForSentMessage( hexpdus );
        }
    }
}

} // namespace FsoGsm
