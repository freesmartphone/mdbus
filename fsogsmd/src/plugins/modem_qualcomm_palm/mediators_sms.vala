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
    /*
     * Helper function to parse a string containing hex bytes.
     * (e.g. "AA18FF94")
     * @return an array of those hex bytes as uint8 numbers.
     */
    private uint8[] stringToByteArray (string s)
    {
        string str = s;
        if (str.length % 2 != 0) str = "0"+str;
        uint8[] arr = new uint8[str.length/2-1];
        var h = new Gee.HashMap<string,uint8>();
        h.set("0",0); h.set("1",1); h.set("2",2);
        h.set("3",3); h.set("4",4); h.set("5",5);
        h.set("6",6); h.set("7",7); h.set("8",8);
        h.set("9",9); h.set("A",10); h.set("B",11);
        h.set("C",12); h.set("D",13); h.set("E",14);
        h.set("F",15); h.set("a",10); h.set("b",11);
        h.set("c",12); h.set("d",13); h.set("e",14);
        h.set("f",15);

        // i=2: skip the first (zero) byte
        for (int i = 2; i < str.length; i += 2)
        {
            arr[i/2-1] = h.get(str[i].to_string())*16+h.get(str[i+1].to_string());
        }
        return arr;
    }

    public override async void run( string recipient_number, string contents, bool want_report ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        string smsc;
        uint8[] arr;
        string curr_pdu;

        validatePhoneNumber( recipient_number );
        var hexpdus = theModem.smshandler.formatTextMessage( recipient_number, contents, want_report );

        var channel = theModem.channel( "main" ) as MsmChannel;
        Msmcomm.SmsTemplateInfo template_info = yield channel.sms_service.message_read_template( Msmcomm.SmsTemplateType.SMSC_NUMBER );
        smsc = template_info.smsc_number;

        for ( int i = 0; i < hexpdus.size; i++)
        {
            curr_pdu = hexpdus.get(i).hexpdu;
            arr = stringToByteArray(curr_pdu);
            // stdout.printf( "%i: %s\n", i, curr_pdu );
            // for (int j = 0; j < arr.length; j++) stdout.printf("%i, ", arr[j]);
            // stdout.printf("\n");
            yield channel.sms_service.send_message( smsc, arr );
        }

        //FIXME: fsogsmd crashes if we don't throw this error.
        throw new FreeSmartphone.Error.UNSUPPORTED( "OK" );
    }
}

// vim:ts=4:sw=4:expandtab
