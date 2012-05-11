/**
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

using GLib;
using FsoGsm;

//===========================================================================
void test_ctzv_to_timezone()
{
    var tz1 = Constants.instance().ctzvToTimeZone( 0x19 );
    assert( tz1 == -165 );

    var tz2 = Constants.instance().ctzvToTimeZone( 35 );
    assert( tz2 == 8*60 );

    var tz3 = Constants.instance().ctzvToTimeZone( 105 );
    assert( tz3 == -4*60 );
}

void test_phone_number_string_to_tuple()
{
    var t0 = Constants.instance().phonenumberStringToTuple( "+1234567890" );
    assert( t0 == "\"1234567890\",145" );

    var t1 = Constants.instance().phonenumberStringToTuple( "0987654321" );
    assert( t1 == "\"0987654321\",129" );
}

void test_phone_number_string_to_real_tuple()
{
    uint8 nt0 = 0;
    var t0 = Constants.instance().phonenumberStringToRealTuple( "+1234567890", out nt0 );
    assert( t0 == "1234567890" );
    assert( nt0 == 145 );

    uint8 nt1 = 0;
    var t1 = Constants.instance().phonenumberStringToRealTuple( "0987654321", out nt1 );
    assert( t1 == "0987654321" );
    assert( nt1 == 129 );
}

//===========================================================================
void main( string[] args )
//===========================================================================
{
    Test.init( ref args );
    Test.add_func( "/Const/ctzvToTimezone", test_ctzv_to_timezone );
    Test.add_func( "/Const/phoneNumberStringToTuple", test_phone_number_string_to_tuple );
    Test.add_func( "/Const/phonenumberStringToRealTuple", test_phone_number_string_to_real_tuple );
    Test.run();
}

// vim:ts=4:sw=4:expandtab
