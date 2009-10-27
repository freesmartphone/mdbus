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

/**
 * Encoders / Decoders etc.
 **/
namespace Codec {

public string hexToString( string hex, uint lowest = 0x20, uint highest = 0x7f, char? subst = null )
{
    var str = new GLib.StringBuilder();

    for ( int i = 0; i < hex.length / 2; ++i )
    {
        var hexbyte = "%c%c".printf( (int)hex[i*2+0], (int)hex[i*2+1] );
        int hexvalue;
        hexbyte.scanf( "%02X", out hexvalue );
        if ( hexvalue >= lowest && hexvalue <= highest )
        {
            str.append_c( (char)hexvalue );
        }
        else
        {
            if ( subst != null )
            {
                str.append_c( subst );
            }
        }
    }
    return str.str;
}

public string decodeSmsPdu( string pdu, int pdulen )
{
    long items_written = -1;
    char[] outbuffer = new char[1024];

    message( "calling decode..." );
    Conversions.decode_hex_own_buf( pdu, -1, out items_written, 0, outbuffer );
    message( "%ld items", items_written );
    //outbuffer.length = 34;

    var sms = Sms.Message();

    var res = Sms.decode( outbuffer, false, pdulen, out sms );
    message( "decode: %d", (int)res );

    if ( res )
    {
        message( "type: %d", sms.type );
        message( "service center: %s", (string)sms.sc_addr.address );
        message( "oaddr: %s", (string)sms.deliver.oaddr.address );
        //message( "userdata: %s", (string)sms.deliver.ud );

        message( "scts: %u/%u/%u %u:%u:%u +%d",
                 sms.deliver.scts.year,
                 sms.deliver.scts.month,
                 sms.deliver.scts.day,
                 sms.deliver.scts.hour,
                 sms.deliver.scts.minute,
                 sms.deliver.scts.second,
                 sms.deliver.scts.timezone );
    }

    return "";
}

} /* namespace Codec */