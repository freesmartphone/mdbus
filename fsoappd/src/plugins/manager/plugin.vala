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

    [DBus (name = "org.freesmartphone.Application.Manager", timeout = 120000)]
    public interface IApplicationManager : Object
    {
        public abstract async void register_session( BusName busname, string appname) 
            throws FreeSmartphone.Application.Error, FreeSmartphone.Error, DBusError, IOError;

        public abstract async void release_session( BusName busname )
            throws FreeSmartphone.Application.Error, FreeSmartphone.Error, DBusError, IOError;
    }

    public class Application : AbstractObject
    {
        private uint busnameWatchRef;

        public BusName busname;
        public string name;
        public FreeSmartphone.Application.Status status;

        public Application( BusName busname, string name )
        {
            this.busname = busname;
            this.name = name;
            this.status = FreeSmartphone.Application.Status.STOPPED;

            busnameWatchRef = GLibHacks.Bus.watch_name( BusType.SYSTEM, busname, BusNameWatcherFlags.NONE, 
                                                        ( connection, name, owner ) => {}, 
                                                        ( connection, name ) => {
                assert( name == this.busname );
                this.disappeared( this ); // DBus signal
            } );

            assert( logger.debug( "Created" ) );
        }

        ~Application()
        {
            Bus.unwatch_name( busnameWatchRef );
            assert( logger.debug( "Destroyed" ) );
        }

        public override string repr()
        {
            return @"<$busname>";
        }

        public signal void disappeared( Application application );
    }

    public class Manager : FsoFramework.AbstractObject,
                           IApplicationManager,
                           FreeSmartphone.Info
    {
        private FsoFramework.Subsystem subsystem;
        private Gee.HashMap<string,Application> applications;
        private AbstractWindowController winctrl;
        private bool ready;

        construct
        {
            applications = new Gee.HashMap<string,Application>();
            ready = false;
        }

        public Manager( FsoFramework.Subsystem subsystem )
        {
            this.subsystem = subsystem;

            subsystem.registerObjectForService<IApplicationManager>( FsoFramework.Application.ServiceDBusName,
                                                                     FsoFramework.Application.ServicePathPrefix,
                                                                     this );
            subsystem.registerObjectForService<FreeSmartphone.Info>( FsoFramework.Application.ServiceDBusName,
                                                                     FsoFramework.Application.ServicePathPrefix,
                                                                     this );

            if ( !createWindowController() )
            {
                return;
            }

            ready = true;
            logger.info( @"Created" );
        }

        private bool createWindowController()
        {
            // create our window controller by type mentioned in the configuration file
            var winctrl_type = theConfig.stringValue( MANAGER_MODULE_NAME, "winctrl_type", "none" );
            string typename = "NullWindowController";

            switch ( winctrl_type )
            {
                case "illume":
                    typename = "IllumeWindowController";
                    break;
            }

            var type = Type.from_name( typename );
            if ( type == Type.INVALID )
            {
               logger.error( @"Got invalid type for window controller \"$(typename)\"; Aborting initialisation ..." ); 
               return false;
            }

            winctrl = Object.new( type ) as AbstractWindowController;

            logger.info( @"Using $(typename) as window controller" );

            return winctrl != null;
        }

        public override string repr()
        {
            return "<>";
        }

        private void handleDisappearingHandlerForApplication( Application application )
        {
            if ( application.status != FreeSmartphone.Application.Status.STOPPED )
            {
                logger.error( "Application disappeared before it arrived the STOPPED state; may it's segfault'ing?");
            }

            applications.unset( application.busname.to_string() );
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
        // DBus API (org.freesmartphone.Application.Manager)
        //

        public async void register_session( BusName busname, string appname ) throws FreeSmartphone.Application.Error, FreeSmartphone.Error
        {
            assert( logger.debug( @"$busname wants to register for a application session" ) );

            var application = applications[busname.to_string()];
            if ( application != null )
            {
                throw new FreeSmartphone.Application.Error.ALREADY_REGISTERED( @"$busname has already a registered application session!" );
            }

            applications[busname.to_string()] = new Application( busname, appname );
            applications[busname.to_string()].disappeared.connect( handleDisappearingHandlerForApplication );
        }

        public async void release_session( BusName busname ) throws FreeSmartphone.Application.Error, FreeSmartphone.Error
        {
            if ( ! ( busname in applications ) )
            {
                throw new FreeSmartphone.Error.INVALID_PARAMETER( "Unsubscribing without ever subscribing is lame" );
            }

            assert( logger.debug( @"$busname wants to release it's application session" ) );

            applications.unset( busname.to_string() );
        }

        public async void activate( string appname ) throws FreeSmartphone.Application.Error, FreeSmartphone.Error
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
