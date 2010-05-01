/*
 * Copyright (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
void test_cb_decode1()
//===========================================================================
{
    var hexpdu = "011000320111C2327BFC76BBCBEE46A3D168341A8D46A3D168341A8D46A3D168341A8D46A3D168341A8D46A3D168341A8D46A3D168341A8D46A3D168341A8D46A3D168341A8D46A3D168341A8D46A3D168341A8D46A3D100";
    var hexpdulen = 88;

    var msg = Cb.Message.newFromHexPdu( hexpdu, hexpdulen );

    string lang;
    var text = msg.decode_all( out lang );

    message( @"lang = $lang; text = $text" );

    assert( lang == "en" );
    assert( text == "Belconnen" );
}

//===========================================================================
void test_cb_decode2()
//===========================================================================
{
    var hexpdu = "001000DD001133DAED46ABD56AB5186CD668341A8D46A3D168341A8D46A3D168341A8D46A3D168341A8D46A3D168341A8D46A3D168341A8D46A3D168341A8D46A3D168341A8D46A3D168341A8D46A3D168341A8D46A3D100";
    var hexpdulen = 88;

    var msg = Cb.Message.newFromHexPdu( hexpdu, hexpdulen );

    string lang;
    var text = msg.decode_all( out lang );

    message( @"lang = $lang; text = $text" );

    assert( lang == "de" );
    assert( text == "347745555103" );
}

//===========================================================================
void test_cb_decode3()
//===========================================================================
{
    var hexpdu = "001000DD001133DAED46ABD56AB5186CD668341A8D46";
    var hexpdulen = 22;

    var msg = Cb.Message.newFromHexPdu( hexpdu, hexpdulen );

    string lang;
    var text = msg.decode_all( out lang );

    message( @"lang = $lang; text = $text" );

    assert( lang == "de" );
    assert( text == "347745555103" );
}

//===========================================================================
void main( string[] args )
//===========================================================================
{
    Test.init( ref args );

    Test.add_func( "/3rdparty/Cb/Decode1", test_cb_decode1 );
    Test.add_func( "/3rdparty/Cb/Decode2", test_cb_decode2 );
    Test.add_func( "/3rdparty/Cb/Decode3", test_cb_decode3 );

    Test.run();
}
