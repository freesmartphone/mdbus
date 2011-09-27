/*
 * Copyright (C) 2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *               2011 Simon Busch <morphis@gravedo.de>
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

namespace Manager
{
    const string MODULE_NAME = "fsopreferences.manager";
}

class Preferences.Manager : FsoFramework.AbstractObject, FreeSmartphone.Preferences
{
    private FsoFramework.Subsystem subsystem;
    private FsoPreferences.ServiceProvider[] services;

    public Manager( FsoFramework.Subsystem subsystem )
    {
        this.subsystem = subsystem;
        subsystem.registerObjectForService<FreeSmartphone.Preferences>(FsoFramework.Preferences.ServiceDBusName,
            FsoFramework.Preferences.ServicePathPrefix, this );
        logger.info( @"Created" );

        Idle.add( () => {
            registerServices();
            sync();
            return false;
        } );
    }

    public override string repr()
    {
        return "<>";
    }

    //
    // private API
    //

    private void registerServices()
    {
        services = new FsoPreferences.ServiceProvider[] {};

        var children = typeof( FsoPreferences.ServiceProvider ).children();
        foreach ( var child in children )
        {
            var obj = Object.new( child );
            if ( obj != null )
            {
                var service = (FsoPreferences.ServiceProvider) obj;
                services += service;
            }
            else
            {
                logger.error( @"Can't instantiate $(child.name())" );
            }
        }

        logger.info( @"Instantiated $(services.length) service providers" );
    }

    private async void sync()
    {
        foreach ( var provider in services )
        {
            yield provider.sync();
        }
    }

    //
    // DBus API
    //

    public async string[] get_services() throws DBusError, IOError
    {
        string[] servicenames = { };

        foreach (var service in services)
        {
            servicenames += service.name;
        }

        return servicenames;
    }

    public async ObjectPath get_service(string name) throws DBusError, IOError
    {
        return null;
    }

    public async string[] get_profiles() throws DBusError, IOError
    {
        return new string[] { };
    }

    public async string get_profile() throws DBusError, IOError
    {
        return "unknown";
    }

    public async void set_profile(string profile) throws DBusError, IOError
    {
    }
}

internal Preferences.Manager instance;

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    instance = new Preferences.Manager( subsystem );
    return Manager.MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsopreferences.manager fso_register_function" );
}

/**
 * This function gets called on plugin load time.
 * @return false, if the plugin operating conditions are present.
 * @note Some versions of glib contain a bug that leads to a SIGSEGV
 * in g_module_open, if you return true here.
 **/
/*public static bool g_module_check_init( void* m )
{
    var ok = FsoFramework.FileHandling.isPresent( Kernel26.SYS_CLASS_LEDS );
    return (!ok);
}
*/

// vim:ts=4:sw=4:expandtab
