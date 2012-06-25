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
[DBus (name = "org.freesmartphone.Testing")]
public interface IDummyObject : GLib.Object
//===========================================================================
{
    public abstract int ThisMethodIsPresent( int value ) throws GLib.Error, GLib.IOError, GLib.DBusError;
}

//===========================================================================
class DummyObject : Object, IDummyObject
//===========================================================================
{
    public int ThisMethodIsPresent( int value ) throws GLib.Error, GLib.IOError, GLib.DBusError
    {
        return value;
    }
}

//===========================================================================
class Pong : Object
//===========================================================================
{
    public bool replied = false;

    private IDummyObject dbusobj;

    public Pong( IDummyObject obj )
    {
        dbusobj = obj;
    }

    public bool ping()
    {
        try
        {
            var value = dbusobj.ThisMethodIsPresent( 42 );
            replied = ( value == 42 );
            if ( replied )
                loop.quit();
        }
        catch ( GLib.Error e )
        {
            error( "%s", e.message );
        }

        return false;
    }
}

/*
//===========================================================================
void test_subsystem_dbus_register_objects()
//===========================================================================
{
    // server side
    var subsystem = new DBusSubsystem( "tests", BusType.SESSION );
    var obj = new DummyObject();
    subsystem.registerObjectForService<IDummyObject>( DBUS_TEST_BUSNAME, DBUS_TEST_OBJPATH, obj );

    // client side
    var dbusobj = Bus.get_proxy_sync<IDummyObject>( BusType.SESSION, DBUS_TEST_BUSNAME, DBUS_TEST_OBJPATH );
    assert( dbusobj != null );

    var pong = new Pong( dbusobj );
    loop = new MainLoop( null, false );

    Idle.add( pong.ping );
    loop.run();

    assert( pong.replied );
}
*/

//===========================================================================
void main (string[] args)
//===========================================================================
{
    Test.init (ref args);

    Test.add_func( "/Subsystem/New", test_subsystem_new );
    Test.add_func( "/Subsystem/RegisterPlugins", test_subsystem_register );
    Test.add_func( "/Subsystem/LoadPlugins", test_subsystem_load );
    // Test.add_func( "/Subsystem/DBusObjects", test_subsystem_dbus_register_objects );

    Test.run ();
}

// vim:ts=4:sw=4:expandtab
