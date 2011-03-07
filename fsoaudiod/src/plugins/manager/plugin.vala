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

    public class Manager : FsoFramework.AbstractObject,
                           FreeSmartphone.Audio.Manager,
                           FreeSmartphone.Info
    {
        private FsoFramework.Subsystem subsystem;
        private FreeSmartphone.Audio.Mode current_mode;
        private FreeSmartphone.Audio.Device current_output_device;
        private FsoAudio.IRouter router;
        private string routertype;

        public Manager( FsoFramework.Subsystem subsystem )
        {
            this.subsystem = subsystem;

            subsystem.registerObjectForService<FreeSmartphone.Audio.Manager>( FsoFramework.Audio.ServiceDBusName, FsoFramework.Audio.ServicePathPrefix, this );
            subsystem.registerObjectForService<FreeSmartphone.Info>( FsoFramework.Audio.ServiceDBusName, FsoFramework.Audio.ServicePathPrefix, this );

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

        public async FreeSmartphone.Audio.Device[] get_available_output_devices( FreeSmartphone.Audio.Mode mode )
            throws FreeSmartphone.Audio.Error, FreeSmartphone.Error, GLib.DBusError, GLib.IOError
        {
            return router.get_available_output_devices( mode );
        }

        public async FreeSmartphone.Audio.Mode get_current_mode()
            throws FreeSmartphone.Audio.Error, FreeSmartphone.Error, GLib.DBusError, GLib.IOError
        {
            return current_mode;
        }

        public async FreeSmartphone.Audio.Device get_current_output_device()
            throws FreeSmartphone.Audio.Error, FreeSmartphone.Error, GLib.DBusError, GLib.IOError
        {
            return current_output_device;
        }

        public async void set_mode( FreeSmartphone.Audio.Mode mode )
            throws FreeSmartphone.Audio.Error, FreeSmartphone.Error, GLib.DBusError, GLib.IOError
        {
            current_mode = mode;
            router.set_mode( current_mode );
        }

        public async void set_output_device( FreeSmartphone.Audio.Device device )
            throws FreeSmartphone.Audio.Error, FreeSmartphone.Error, GLib.DBusError, GLib.IOError
        {
            current_output_device = device;
            router.set_output_device( current_output_device );
        }

        public async void set_microphone_mute( bool mute )
            throws FreeSmartphone.Audio.Error, FreeSmartphone.Error, GLib.DBusError, GLib.IOError
        {
            throw new FreeSmartphone.Error.UNSUPPORTED( "Not yet implemented!" );
        }

        public async bool get_microphone_mute()
            throws FreeSmartphone.Audio.Error, FreeSmartphone.Error, GLib.DBusError, GLib.IOError
        {
            throw new FreeSmartphone.Error.UNSUPPORTED( "Not yet implemented!" );
        }

        public async void mute() throws FreeSmartphone.Error, GLib.DBusError, GLib.IOError
        {
        }

        public async void set_volume (int volume) throws FreeSmartphone.Error, GLib.DBusError, GLib.IOError
        {
        }

        public async void unmute () throws FreeSmartphone.Error, GLib.DBusError, GLib.IOError
        {
        }

        public signal void volume_changed( FreeSmartphone.Audio.Device device, int volume );
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
