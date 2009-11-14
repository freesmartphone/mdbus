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
public void test_const_mbpi_create()
//===========================================================================
{
    var mbpi = MBPI.Database.instance();
    assert( mbpi.allCountries()["de"].name == "germany" );
}

//===========================================================================
public void test_const_lookup_access_points()
//===========================================================================
{
    var mbpi = MBPI.Database.instance();
    var aps = mbpi.accessPointsForMccMnc( "26203" );
    assert( aps.size == 1 );
    assert( aps["internet.eplus.de"].name == "internet.eplus.de" );
}

//===========================================================================
void main( string[] args )
//===========================================================================
{
    Test.init( ref args );

    Test.add_func( "/Const/MBPI/Create", test_const_mbpi_create );
    Test.add_func( "/Const/MBPI/LookupAccessPoints", test_const_lookup_access_points );

    Test.run();
}
