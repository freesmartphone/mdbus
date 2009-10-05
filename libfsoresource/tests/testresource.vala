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

const string DBUS_TEST_BUSNAME = "org.freesmartphone.testing";
const string DBUS_TEST_OBJPATH = "/org/freesmartphone/Testing";
const string DBUS_TEST_INTERFACE = "org.freesmartphone.Testing";

MainLoop loop;

public class DummyResource : AbstractBaseResource
{
    public status = "unknown";
}

void async testit()
{
    
}

//===========================================================================
void test_resource_all()
//===========================================================================
{
    // setup server side
    var subsystem = new DBusSubsystem( "tests" );
    var ok = subsystem.registerServiceName( DBUS_TEST_BUSNAME );
    assert ( ok );
    var obj = new DummyResource( subsystem );
    subsystem.registerServiceObject( DBUS_TEST_BUSNAME, DBUS_TEST_OBJPATH, obj );

    testit.begin();
    loop = new MainLoop();
    loop.run();
}

//===========================================================================
void main( string[] args )
//===========================================================================
{
    Test.init( ref args );

    Test.add_func( "/Resource/all", test_resource_all );

    Test.run();
}
