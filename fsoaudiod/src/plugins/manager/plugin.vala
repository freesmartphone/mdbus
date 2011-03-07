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

namespace FsoAudio
{
    const string MANAGER_MODULE_NAME = "fsoaudio.manager";

    class DeviceControl : FsoFramework.AbstractObject
    {
        public string name;
        public uint current_raw_volume;

        public DeviceControl( string name )
        {
            this.name;
        }

        public void exposeToRouter( IRouter router )
        {
        }

        public override string repr()
        {
            return "<>";
        }
    }

    class Manager : FsoFramework.AbstractObject, FreeSmartphone.Audio.Manager
    {
        private FsoFramework.Subsystem subsystem;
        private FreeSmartphone.Audio.Mode current_mode;
        private FsoAudio.IRouter router;
        private string routertype;
        private Gee.HashMap<string,DeviceControl> input_controls;
        private Gee.HashMap<string,DeviceControl> output_controls;

        public Manager( FsoFramework.Subsystem subsystem )
        {
            this.subsystem = subsystem;

            current_mode = FreeSmartphone.Audio.Mode.NORMAL;

            var routername = config.stringValue( MANAGER_MODULE_NAME, "router_type", "" );
            var typename = "";

            switch ( routername )
            {
    #if 0
                case "alsa":
                    typename = "RouterLibAlsa";
                    break;
    #endif
                case "palmpre":
                    typename = "RouterPalmPre";
                    break;
    #if 0
                case "qdsp5":
                    typename = "RouterQdsp5";
                    break;
    #endif
                default:
                    typename = "NullRouter";
                    break;
            }

            var routertype = GLib.Type.from_name( typename );
            if ( routertype == GLib.Type.INVALID )
            {
                logger.warning( @"Can't instanciate requested router type $typename; will not be able to route audio" );
                router = new FsoAudio.NullRouter();
                this.routertype = "NullRouter";
            }
            else
            {
                router = (FsoAudio.IRouter) GLib.Object.new( routertype );
                this.routertype = typename;
            }

            input_controls = createDeviceControls( router.get_available_output_devices() );
            output_controls = createDeviceControls( router.get_available_input_devices() );

            logger.info( @"Created" );
        }

        public override string repr()
        {
            return "<>";
        }

        private Gee.HashMap<string,DeviceControl> createDeviceControls( string[] control_names )
        {
            var controls = new Gee.HashMap<string,DeviceControl>();

            foreach ( string name in control_names )
            {
                controls.set( name, new DeviceControl( name ) );
                assert( logger.debug( @"Created new audio control '$name'" ) );
            }

            return controls;
        }

        //
        // DBus API (org.freesmartphone.Audio.Manager)
        //

        public async string[] get_available_input_devices( FreeSmartphone.Audio.Mode mode )
            throws FreeSmartphone.Audio.Error, FreeSmartphone.Error, GLib.DBusError, GLib.IOError
        {
            return router.get_available_input_devices();
        }

        public async string[] get_available_output_devices( FreeSmartphone.Audio.Mode mode )
            throws FreeSmartphone.Audio.Error, FreeSmartphone.Error, GLib.DBusError, GLib.IOError
        {
            return router.get_available_output_devices();
        }

        public async GLib.ObjectPath get_current_input_device()
            throws FreeSmartphone.Audio.Error, FreeSmartphone.Error, GLib.DBusError, GLib.IOError
        {
            return null;
        }

        public async FreeSmartphone.Audio.Mode get_current_mode()
            throws FreeSmartphone.Audio.Error, FreeSmartphone.Error, GLib.DBusError, GLib.IOError
        {
            return current_mode;
        }

        public async GLib.ObjectPath get_current_output_device()
            throws FreeSmartphone.Audio.Error, FreeSmartphone.Error, GLib.DBusError, GLib.IOError
        {
            return null;
        }

        public async void set_input_device( string name )
            throws FreeSmartphone.Audio.Error, FreeSmartphone.Error, GLib.DBusError, GLib.IOError
        {
        }

        public async void set_mode( FreeSmartphone.Audio.Mode mode )
            throws FreeSmartphone.Audio.Error, FreeSmartphone.Error, GLib.DBusError, GLib.IOError
        {
        }

        public async void set_output_device( string name )
            throws FreeSmartphone.Audio.Error, FreeSmartphone.Error, GLib.DBusError, GLib.IOError
        {
        }
    }
}

internal FsoAudio.Manager instance;

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    instance = new FsoAudio.Manager( subsystem );
    return FsoAudio.MANAGER_MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsoaudio.manager fso_register_function" );
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
