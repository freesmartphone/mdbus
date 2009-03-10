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
using FsoFramework;

//===========================================================================
void test_subsystem_all()
//===========================================================================
{
    var subsystem = new BaseSubsystem( "tests" );
    subsystem.registerPlugins();
    var info = subsystem.pluginsInfo();
    assert ( info.length() == 3 );
    var pinfo = info.nth_data(0);
    assert ( !pinfo.loaded );
    subsystem.loadPlugins();
    pinfo = info.nth_data( 0 );
    assert ( pinfo.loaded );
    assert ( pinfo.name == "tests.plugin1" );
    pinfo = info.nth_data( 1 );
    assert ( pinfo.loaded );
    assert ( pinfo.name == "tests.plugin2" );
    pinfo = info.nth_data( 2 );
    assert ( pinfo.loaded );
    assert ( pinfo.name == "tests.plugin3" );
}

//===========================================================================
void main (string[] args)
//===========================================================================
{
    Test.init (ref args);

    Test.add_func( "/Subsystem/All", test_subsystem_all );

    Test.run ();
}
