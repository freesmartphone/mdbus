/**
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
using FsoFramework;

const string DBUS_TEST_BUSNAME = "org.freesmartphone.testing";
const string DBUS_TEST_OBJPATH = "/org/freesmartphone/Testing";
const string DBUS_TEST_INTERFACE = "org.freesmartphone.Testing";

MainLoop loop;

//===========================================================================
void test_subsystem_new()
//===========================================================================
{
    var subsystem = new BaseSubsystem( "tests" );
}

//===========================================================================
void test_subsystem_register()
//===========================================================================
{
    var subsystem = new BaseSubsystem( "tests" );
    subsystem.registerPlugins();
}

//===========================================================================
void test_subsystem_load()
//===========================================================================
{
    var subsystem = new BaseSubsystem( "tests" );
    var number = subsystem.registerPlugins();
    var info = subsystem.pluginsInfo();
    assert ( number == 3 );
    assert ( info.length() == 3 );
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
    pinfo = info.nth_data( 2 );
    assert ( !pinfo.loaded );
    assert ( pinfo.name == null );
}

//===========================================================================
void test_subsystem_dbus_register_name()
//===========================================================================
{
    // FIXME: Something is wrong in teardown handling here. If, instead of
    // org.freesmartphone.ogsmd, you try to do this with DBUS_TEST_BUSNAME,
    // you will get an assertion in gdbus_proxy moaning about "unassociated objects"
    // This might as well be a bug in dbus-glib or dbus :/
    var subsystem = new DBusSubsystem( "tests" );
    var ok1 = subsystem.registerServiceName( "org.freesmartphone.ogsmd" );
    assert ( ok1 );
    var ok2 = subsystem.registerServiceName( "org.freesmartphone.ogsmd" );
    assert ( ok2 );
}

//===========================================================================
[DBus (name = "org.freesmartphone.Testing")]
//===========================================================================
class DummyObject : Object
{
    public int ThisMethodIsPresent( int value ) throws DBus.Error
    {
        return value;
    }
}

//===========================================================================
class Pong : Object
//===========================================================================
{
    public bool replied = false;
    dynamic DBus.Object dbusobj;

    public Pong( dynamic DBus.Object obj )
    {
        dbusobj = obj;
    }

    public void reply( int value, Error e )
    {
        replied = ( value == 42 );
        if ( replied )
            loop.quit();
    }

    public bool call()
    {
        try
        {
            dbusobj.ThisMethodIsPresent( 42, reply );
        }
        catch ( DBus.Error e )
        {
            error( "%s", e.message );
        }
        return false;
    }
}

//===========================================================================
void test_subsystem_dbus_register_objects()
//===========================================================================
{
    // server side
    var subsystem = new DBusSubsystem( "tests" );
    var ok = subsystem.registerServiceName( DBUS_TEST_BUSNAME );
    assert ( ok );
    var obj = new DummyObject();
    subsystem.registerServiceObject( DBUS_TEST_BUSNAME, DBUS_TEST_OBJPATH, obj );

    // client side
    var conn = DBus.Bus.get( DBus.BusType.SYSTEM );
    dynamic DBus.Object dbusobj = conn.get_object( DBUS_TEST_BUSNAME, DBUS_TEST_OBJPATH, DBUS_TEST_INTERFACE );
    assert( dbusobj != null );

    var pong = new Pong( dbusobj );
    loop = new MainLoop( null, false );

    Idle.add( pong.call );
    loop.run();

    assert( pong.replied );
}

//===========================================================================
void main (string[] args)
//===========================================================================
{
    Test.init (ref args);

    Test.add_func( "/Subsystem/New", test_subsystem_new );
    Test.add_func( "/Subsystem/RegisterPlugins", test_subsystem_register );
    Test.add_func( "/Subsystem/LoadPlugins", test_subsystem_load );
    Test.add_func( "/Subsystem/DBusName", test_subsystem_dbus_register_name );
    Test.add_func( "/Subsystem/DBusObjects", test_subsystem_dbus_register_objects );

    Test.run ();
}
