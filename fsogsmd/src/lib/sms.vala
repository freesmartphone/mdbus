/**
 * Copyright (C) 2009 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
 * @class ShortMessage
 *
 * Higher level SMS abstraction on top of the lowlevel 3rdparty SMS code
 **/
public class ShortMessage
{
    public string number { get; set; }
    //FIXME: might rather be a uint8[] (for binary SMS)?
    public string contents { get; set; }

    public ShortMessage( string number, string contents, GLib.HashTable<string,Value?>? properties = null )
    {
        this.number = number;
        this.contents = contents;
        if ( properties != null )
        {
            //FIXME handle properties
        }
    }

    public static ShortMessage decodeFromHexPdu( string pdu, int tpdulen )
    {
        long items_written = -1;
        char[] outbuffer = new char[1024];
        Conversions.decode_hex_own_buf( pdu, -1, out items_written, 0, outbuffer );
        message( "%ld items", items_written );

        var sms = Sms.Message();
        var res = Sms.decode( outbuffer, false, tpdulen, out sms );
        message( "decode: %d", (int)res );

        if ( res )
        {
            message( "type: %d", sms.type );
            message( "service center: %s", sms.sc_addr.to_string() );
            message( "number: %s", sms.number() );

            message( "scts: %u/%u/%u %u:%u:%u +%d",
                     sms.deliver.scts.year,
                     sms.deliver.scts.month,
                     sms.deliver.scts.day,
                     sms.deliver.scts.hour,
                     sms.deliver.scts.minute,
                     sms.deliver.scts.second,
                     sms.deliver.scts.timezone );
            message( "text: '%s'", sms.to_string() );

            var instance = new ShortMessage( sms.number(), sms.to_string() );
            return instance;
        }
        else
        {
            return null;
        }
    }

    public struct HexPdu
    {
        string pdu;
        int tpdulen;
    }

    public static HexPdu[] formatTextMessage( string number, string contents, uint8 reference )
    {
        int offset;
        var smslist = Sms.text_prepare( contents, 0, true, out offset );

        debug( "formatTextMessage: will create %u hexpdus", smslist.length() );

        var hexpdus = new HexPdu[smslist.length()] {};

        // set reference number and to address
        smslist.foreach( (element) =>
        {
            var psms = (Sms.Message*)element;

            if ( offset != 0 )
            {
                psms->submit.ud[offset] = (reference & 0xf0) >> 8;
                psms->submit.ud[offset+1] = (reference & 0x0f);
            }

            psms->submit.daddr.from_string( number );
        } );

        char[] binpdu = new char[176];
        char[] hexpdu = new char[1024];
        var pdulen = 0;
        var tpdulen = 0;
        uint i = 0;

        // convert to PDU
        smslist.foreach( (element) =>
        {
            var psms = (Sms.Message*)element;

            var ok = Sms.encode( *psms, out pdulen, out tpdulen, binpdu );
            assert( ok );

            Conversions.encode_hex_own_buf( binpdu, 0, hexpdu );
            debug( "formatTextMessage: hexpdu created w/ tpdulen = %d", tpdulen );
            hexpdus[i++] = HexPdu() { pdu=(string)hexpdu, tpdulen=tpdulen };
        } );

        return hexpdus;
    }
}

} /* namespace FsoGsm */
