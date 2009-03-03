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
void test_plugin_all()
//===========================================================================
{
    Plugin p;

    p = new BasePlugin( "./this/path/not/existing" );
    try
    {
        p.load();
        assert( false ); // supposed to throw an error
    }
    catch ( PluginError e )
    {
        // ok
    }

    p = new BasePlugin( "./.libs/plugin" );
    p.load();

    var info = p.info();

    assert ( info.name == "test.plugin" );
    assert ( info.loaded );
}

//===========================================================================
void main (string[] args)
//===========================================================================
{
    Test.init (ref args);

    Test.add_func ("/Plugin/all", test_plugin_all);

    Test.run ();
}
