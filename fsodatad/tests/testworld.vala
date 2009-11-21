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
using FsoData;

//===========================================================================
public void test_world_mbpi_create()
//===========================================================================
{
    var mbpi = MBPI.Database.instance();
    var germany = mbpi.allCountries()["de"];
    assert( germany != null );
    assert( germany.name.down() == "germany" );
    assert( germany.dialprefix == "49" );
    assert( germany.timezones.size == 1 );
    assert( germany.timezones[0] == "UTC+01:00" );
}

//===========================================================================
public void test_world_mbpi_lookup_access_points()
//===========================================================================
{
    var mbpi = MBPI.Database.instance();
    var aps = mbpi.accessPointsForMccMnc( "26203" );
    assert( aps.size == 1 );
    assert( aps["internet.eplus.de"].name == "internet.eplus.de" );
}

//===========================================================================
public void test_world_mbpi_lookup_countries()
//===========================================================================
{
    var mbpi = MBPI.Database.instance();
    var notfound = mbpi.countryForMccMnc( "999999" );
    assert( notfound == null );
    var germany = mbpi.countryForMccMnc( "26203" );
    assert( germany != null );
    assert( germany.name.down() == "germany" );
    assert( germany.code.down() == "de" );
}
//===========================================================================
void main (string[] args)
//===========================================================================
{
    Test.init (ref args);
    Test.add_func( "/FsoData/World/MBPI/Create", test_world_mbpi_create );
    Test.add_func( "/FsoData/World/MBPI/LookupAPN", test_world_mbpi_lookup_access_points );
    Test.add_func( "/FsoData/World/MBPI/LookupCountry", test_world_mbpi_lookup_countries );
    Test.run ();
}
