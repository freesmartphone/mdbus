/*
 * Copyright (C) 2011 Simon Busch <morphis@gravedo.de>
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

namespace FsoApp
{
    const string MANAGER_MODULE_NAME = "fsoapp.manager";

    public class Manager : FsoFramework.AbstractObject,
                           FreeSmartphone.Application.Manager,
                           FreeSmartphone.Info
    {
        private FsoFramework.Subsystem subsystem;

        public Manager( FsoFramework.Subsystem subsystem )
        {
            this.subsystem = subsystem;

            subsystem.registerObjectForService<FreeSmartphone.Application.Manager>( FsoFramework.Application.ServiceDBusName,
                                                                                    FsoFramework.Application.ServicePathPrefix,
                                                                                    this );
            subsystem.registerObjectForService<FreeSmartphone.Info>( FsoFramework.Application.ServiceDBusName,
                                                                     FsoFramework.Application.ServicePathPrefix,
                                                                     this );

            logger.info( @"Created" );
        }

        public override string repr()
        {
            return "<>";
        }

        //
        // DBus API (org.freesmartphone.Info)
        //

        public async HashTable<string,Variant> get_info() throws DBusError, IOError
        {
            var dict = new HashTable<string,Variant>( str_hash, str_equal );
            return dict;
        }

        //
        // DBus API (org.freesmartphone.Audio.Manager)
        //

        public async void register_session( string appname ) throws FreeSmartphone.Application.Error, FreeSmartphone.Error
        {
        }

        public async void release_session() throws FreeSmartphone.Application.Error, FreeSmartphone.Error
        {
        }
    }
}

internal FsoApp.Manager instance;

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    instance = new FsoApp.Manager( subsystem );
    return FsoApp.MANAGER_MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsoapp.manager fso_register_function" );
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
