/**
 * Copyright (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
    message( @"$tz1" );
    assert( tz1 == -165 );

    var tz2 = Constants.instance().ctzvToTimeZone( 35 );
    message( @"$tz2" );
    assert( tz2 == 8*60 );

    var tz3 = Constants.instance().ctzvToTimeZone( 105 );
    message( @"$tz3" );
    assert( tz3 == -4*60 );
}

//===========================================================================
void main( string[] args )
//===========================================================================
{
    Test.init( ref args );
    Test.add_func( "/Const/ctzvToTimezone", test_ctzv_to_timezone );
    Test.run();
}
