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
    //FIXME: plugin error bug in vala
    assert ( info.length() == 3 );
    //assert ( info.length() == 2 );
    var pinfo = info.nth_data(0);
    assert ( !pinfo.loaded );

    subsystem.loadPlugins();
    info = subsystem.pluginsInfo();
    pinfo = info.nth_data( 0 );
    assert ( pinfo.loaded );
    assert ( pinfo.name == "tests.plugina" );
    pinfo = info.nth_data( 1 );
    assert ( pinfo.loaded );
    assert ( pinfo.name == "tests.pluginb" );
}

//===========================================================================
void main (string[] args)
//===========================================================================
{
    Test.init (ref args);

    Test.add_func( "/Subsystem/All", test_subsystem_all );

    Test.run ();
}
