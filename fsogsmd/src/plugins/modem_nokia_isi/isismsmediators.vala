/*
 * Copyright (C) 2011 Klaus 'mrmoku' Kurzmann <mok@fluxnetz.de>
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

namespace NokiaIsi
{
/*
 * org.freesmartphone.GSM.SMS
 */


/* pending for implementation of SIM side */
//public class IsiSmsRetrieveTextMessages : SmsRetrieveTextMessages
//{
//}

public class IsiSmsSendTextMessage : SmsSendTextMessage
{
    public override async void run( string recipient_number, string contents, bool want_report ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        validatePhoneNumber( recipient_number );

        var hexpdus = modem.smshandler.formatTextMessage( recipient_number, contents, want_report );

        transaction_index = modem.smshandler.lastReferenceNumber();
        //FIXME: What about ACK PDUs?
        timestamp = "now";

        // remember transaction indizes for later
        if ( want_report )
        {
            modem.smshandler.storeTransactionIndizesForSentMessage( hexpdus );
        }
    }
}

} // namespace NokiaIsi

// vim:ts=4:sw=4:expandtab
