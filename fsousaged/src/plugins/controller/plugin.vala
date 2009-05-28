/*
 * Generic Resource Controller
 *
 * Written by Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 * All Rights Reserved
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */

using GLib;
using Gee;

internal const string DBUS_BUS_NAME = "org.freedesktop.DBus";
internal const string DBUS_BUS_PATH = "/org/freedesktop/DBus";
internal const string DBUS_BUS_INTERFACE = "org.freedesktop.DBus";

namespace Usage
{

/**
 * Helper class encapsulating a registered resource
 **/
public class Resource
{
    public string name;
    public DBus.BusName busname;
    public DBus.ObjectPath objectpath;

    public Resource( string name, DBus.BusName busname, DBus.ObjectPath objectpath )
    {
        this.name = name;
        this.busname = busname;
        this.objectpath = objectpath;
        message( "Resource %s served by %s @ %s created", name, busname, objectpath );
    }

    ~Resource()
    {
        message( "Resource %s served by %s @ %s destroyed", name, busname, objectpath );
    }
}

/**
 * Controller class implementing org.freesmartphone.Usage API
 *
 * Note: Unfortunately we can't just use libfso-glib (FreeSmartphone.Usage interface)
 * here, since we do some tricks with the dbus sender name,
 **/
[DBus (name = "org.freesmartphone.Usage")]
public class Controller : FsoFramework.AbstractObject
{
    private FsoFramework.Subsystem subsystem;
    HashMap<string,Resource> resources;

    DBus.Connection conn;
    dynamic DBus.Object dbus;

    public Controller( FsoFramework.Subsystem subsystem )
    {
        this.subsystem = subsystem;

        resources = new HashMap<string,Resource>( str_hash, str_equal, str_equal );

        this.subsystem.registerServiceName( FsoFramework.Usage.ServiceDBusName );
        this.subsystem.registerServiceObject( FsoFramework.Usage.ServiceDBusName,
                                              FsoFramework.Usage.ServicePathPrefix, this );

        conn = DBus.Bus.get( DBus.BusType.SYSTEM );
        dbus = conn.get_object( DBUS_BUS_NAME, DBUS_BUS_PATH, DBUS_BUS_INTERFACE );
        dbus.NameOwnerChanged += onNameOwnerChanged;
    }

    public override string repr()
    {
        return "<%s>".printf( FsoFramework.ServicePathPrefix );
    }

    private void onResourceAppearing( Resource r )
    {
        logger.debug( "Resource %s served by %s @ %s has just been registered".printf( r.name, r.busname, (string)r.objectpath ) );
        this.resource_available( r.name, true ); // DBUS SIGNAL
    }

    private void onResourceVanishing( Resource r )
    {
        logger.debug( "Resource %s served by %s @ %s has just been unregistered".printf( r.name, r.busname, (string)r.objectpath ) );
        this.resource_available( r.name, false ); // DBUS SIGNAL
    }

    private void onNameOwnerChanged( dynamic DBus.Object obj, string name, string oldowner, string newowner )
    {
        //message( "name owner changed: %s (%s => %s)", name, oldowner, newowner );
        // we're only interested in services disappearing
        if ( newowner != "" )
            return;

        logger.debug( "%s disappeared. checking whether resources are affected...".printf( name ) );
        foreach ( var r in resources.get_values() )
        {
            if ( r.busname == name )
            {
                onResourceVanishing( r );
                resources.remove( r.name );
            }
        }
    }

    //
    // DBUS API (for providers)
    //
    public void register_resource( DBus.BusName sender, string name, DBus.ObjectPath path ) throws FreeSmartphone.UsageError, DBus.Error
    {
        message( "register_resource called with parameters: %s %s %s", sender, name, path );
        if ( name in resources )
            throw new FreeSmartphone.UsageError.RESOURCE_EXISTS( "Resource %s already registered".printf( name ) );

        var r = new Resource( name, sender, path );
        resources[name] = r;

        onResourceAppearing( r );
    }

    public void unregister_resource( DBus.BusName sender, string name ) throws FreeSmartphone.UsageError, DBus.Error
    {
        var r = resources[name];

        if ( r == null )
            throw new FreeSmartphone.UsageError.RESOURCE_UNKNOWN( "Resource %s had never been registered".printf( name ) );

        if ( r.busname != sender )
            throw new FreeSmartphone.UsageError.RESOURCE_UNKNOWN( "Resource %s not yours".printf( name ) );

        onResourceVanishing( r );

        resources.remove( name );
    }

    //
    // DBUS API (for consumers)
    //
    public string get_resource_policy( string name ) throws FreeSmartphone.UsageError, DBus.Error
    {
        return "";
    }

    public bool get_resource_state( string name ) throws FreeSmartphone.UsageError, DBus.Error
    {
        return false;
    }

    public string[] get_resource_users( string name ) throws FreeSmartphone.UsageError, DBus.Error
    {
        return {};
    }

    public string[] list_resources() throws DBus.Error
    {
        return {};
    }

    public void release_resource( string name ) throws FreeSmartphone.UsageError, DBus.Error
    {
    }

    public void request_resource( string name ) throws FreeSmartphone.UsageError, DBus.Error
    {
    }

    public void set_resource_policy( string name, string policy ) throws FreeSmartphone.UsageError, DBus.Error
    {
    }

    public void shutdown() throws DBus.Error
    {
    }

    public void reboot() throws DBus.Error
    {
    }

    public void suspend() throws DBus.Error
    {
    }

    public signal void resource_available( string name, bool availability );
    public signal void resource_changed( string name, bool state, GLib.HashTable<string,GLib.Value?> attributes );
    public signal void system_action( string action );
}

} /* end namespace */

Usage.Controller instance;

public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    instance = new Usage.Controller( subsystem );
    return "fsousage.controller";
}



[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    debug( "usage controller fso_register_function()" );
}
