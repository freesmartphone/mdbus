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

using GLib;
using FsoGsm;

//===========================================================================
void test_sms_decode()
//===========================================================================
{
    string pdu = "0791947107160000040C9194712716464600008021810270854008CB729D5D76B95C";
    int tpdulen = 26;

    var sms = ShortMessage.decodeFromHexPdu( pdu, tpdulen );
    assert( sms != null );
}

//===========================================================================
void test_sms_encode()
//===========================================================================
{
    uint8 refnum;
    int tpdulen;
    var pdus = ShortMessage.formatTextMessage( "+1234567890", "Keule...", out refnum );
}

//===========================================================================
void main( string[] args )
//===========================================================================
{
    Test.init( ref args );

    Test.add_func( "/Conversions/Sms/Decode", test_sms_decode );
    Test.add_func( "/Conversions/Sms/Encode", test_sms_encode );

    Test.run();
}
