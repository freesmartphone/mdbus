/*
 * Copyright (C) 2010-2011 Simon Busch <morphis@gravedo.de>
 *                         Lukas Märdian <lukasmaerdian@gmail.com>
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

/**
 * SMS Mediators
 **/
public class MsmSmsRetrieveTextMessages : SmsRetrieveTextMessages
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.UNSUPPORTED( "Not yet implemented!" );
    }
}

public class MsmSmsGetSizeForTextMessage : SmsGetSizeForTextMessage
{
    public override async void run( string contents ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.UNSUPPORTED( "Not yet implemented!" );
    }
}

public class MsmSmsSendTextMessage : SmsSendTextMessage
{
    /**
     * Helper function to parse a string containing hex bytes.
     * (e.g. "AA18FF94")
     * @return an array of those hex bytes as uint8 numbers.
     **/
    private uint8[] stringToByteArray (string s)
    {
        string str = s;
        if (str.length % 2 != 0) str = "0"+str;
        uint8[] arr = new uint8[str.length/2];
        var h = new Gee.HashMap<string,uint8>();
        h.set("0",0); h.set("1",1); h.set("2",2);
        h.set("3",3); h.set("4",4); h.set("5",5);
        h.set("6",6); h.set("7",7); h.set("8",8);
        h.set("9",9); h.set("A",10); h.set("B",11);
        h.set("C",12); h.set("D",13); h.set("E",14);
        h.set("F",15); h.set("a",10); h.set("b",11);
        h.set("c",12); h.set("d",13); h.set("e",14);
        h.set("f",15);

        for (int i = 0; i < str.length; i += 2)
        {
            arr[i/2] = h.get(str[i].to_string())*16+h.get(str[i+1].to_string());
        }
        return arr;
    }

    public override async void run( string recipient_number, string contents, bool want_report ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var channel = theModem.channel( "main" ) as MsmChannel;
        string smsc = "";
        uint8[] byte_pdu;

        validatePhoneNumber( recipient_number );
        var hexpdus = theModem.smshandler.formatTextMessage( recipient_number, contents, want_report );

        // gather SMSC number
        try
        {
            var template_info = yield channel.sms_service.message_read_template( Msmcomm.SmsTemplateType.SMSC_NUMBER );
            smsc = template_info.smsc_number;
        }
        catch ( GLib.Error err )
        {
            var msg = @"Could not gather SMSC number, got: $(err.message)";
            throw new FreeSmartphone.Error.INTERNAL_ERROR( msg );
        }

        foreach ( var pdu in hexpdus)
        {
            int len = pdu.hexpdu.length;
            // skip first byte (length of SMSC information), as msmcomm wants just the raw PDU
            byte_pdu = stringToByteArray(pdu.hexpdu[2:len]);
            try
            {
                yield channel.sms_service.send_message( smsc, byte_pdu );
                // TODO (from atsmsmediators): hexpdu.transaction_index = cmd.refnum;
                stdout.printf( @"send_message: $smsc, $recipient_number, $contents\n" );
                stdout.printf( @"send_message: $(pdu.hexpdu[2:len])\n" );
            }
            catch ( GLib.Error err1 )
            {
                var msg1 = @"Could not process send_message, got: $(err1.message)";
                throw new FreeSmartphone.Error.INTERNAL_ERROR( msg1 );
            }
        }

        transaction_index = theModem.smshandler.lastReferenceNumber();
        timestamp = "now";
    }
}

// vim:ts=4:sw=4:expandtab
