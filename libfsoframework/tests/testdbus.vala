/**
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
void test_dbus_masterkeyfile()
//===========================================================================
{
    var mkf = SmartKeyFile.defaultKeyFile();
}

//===========================================================================
void test_dbus_is_valid_dbus_name()
//===========================================================================
{
    assert( isValidDBusName( "org.foo" ) );
    assert( isValidDBusName( "org.foo.bar" ) );
    assert( isValidDBusName( "org.foo.bar.baz" ) );
    assert( ! isValidDBusName( "org" ) );
    assert( ! isValidDBusName( "org." ) );
    assert( ! isValidDBusName( "foo.org." ) );
    assert( ! isValidDBusName( ".org.yo.kurt" ) );
}

//===========================================================================
void main( string[] args )
//===========================================================================
{
    Test.init( ref args );

    Test.add_func( "/Common/masterKeyFile", test_dbus_masterkeyfile );
    Test.add_func( "/DBus/isValidDBusName", test_dbus_is_valid_dbus_name );

    Test.run();
}

// vim:ts=4:sw=4:expandtab
