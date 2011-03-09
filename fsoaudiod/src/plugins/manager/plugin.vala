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

    public class ControlInfo
    {
        public FreeSmartphone.Audio.Control type;
        public int volume;
        public bool muted;

        public ControlInfo( FreeSmartphone.Audio.Control type, int volume )
        {
            this.type = type;
            this.volume = volume;
            this.muted = ( this.volume == 0 );
        }
    }

    public class DeviceInfo
    {
        public FreeSmartphone.Audio.Device type;
        public ControlInfo[] call_controls;
        public ControlInfo[] normal_controls;

        public DeviceInfo( FreeSmartphone.Audio.Device type )
        {
            this.type = type;
            normal_controls = new ControlInfo[] {
                new ControlInfo( FreeSmartphone.Audio.Control.SPEAKER, 80 ),
                new ControlInfo( FreeSmartphone.Audio.Control.MICROPHONE, 80 )
            };
            call_controls = new ControlInfo[] {
                new ControlInfo( FreeSmartphone.Audio.Control.SPEAKER, 80 ),
                new ControlInfo( FreeSmartphone.Audio.Control.MICROPHONE, 80 )
            };
        }

        private ControlInfo[] get_controls( FreeSmartphone.Audio.Mode mode )
        {
            return mode == FreeSmartphone.Audio.Mode.NORMAL ? normal_controls : call_controls;
        }

        public void set_volume( FreeSmartphone.Audio.Mode mode, FreeSmartphone.Audio.Control ctrl, int volume )
        {
            var controls = get_controls( mode );
            controls[ ctrl ].volume = volume;
        }

        public int get_volume( FreeSmartphone.Audio.Mode mode, FreeSmartphone.Audio.Control ctrl )
        {
            var controls = get_controls( mode );
            return controls[ ctrl ].volume;
        }

        public void set_mute( FreeSmartphone.Audio.Mode mode, FreeSmartphone.Audio.Control ctrl, bool mute )
        {
            var controls = get_controls( mode );
            controls[ ctrl].muted = mute;
        }

        public bool get_mute( FreeSmartphone.Audio.Mode mode, FreeSmartphone.Audio.Control ctrl )
        {
            var controls = get_controls( mode );
            return controls[ ctrl ].muted;
        }
    }

    public class Manager : FsoFramework.AbstractObject,
                           FreeSmartphone.Audio.Manager,
                           FreeSmartphone.Info
    {
        private FsoFramework.Subsystem subsystem;
        private FreeSmartphone.Audio.Mode current_mode;
        private FsoAudio.IRouter router;
        private string routertype;
        private DeviceInfo[] devices;

        private FreeSmartphone.Audio.Device current_device;

        public Manager( FsoFramework.Subsystem subsystem )
        {
            this.subsystem = subsystem;

            subsystem.registerObjectForService<FreeSmartphone.Audio.Manager>( FsoFramework.Audio.ServiceDBusName,
                                                                              FsoFramework.Audio.ServicePathPrefix,
                                                                              this );
            subsystem.registerObjectForService<FreeSmartphone.Info>( FsoFramework.Audio.ServiceDBusName,
                                                                     FsoFramework.Audio.ServicePathPrefix,
                                                                     this );

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

            devices = new DeviceInfo[] {
                new DeviceInfo( FreeSmartphone.Audio.Device.BACKSPEAKER ),
                new DeviceInfo( FreeSmartphone.Audio.Device.FRONTSPEAKER ),
                new DeviceInfo( FreeSmartphone.Audio.Device.HEADSET ),
                new DeviceInfo( FreeSmartphone.Audio.Device.BLUETOOTH_SCO ),
                new DeviceInfo( FreeSmartphone.Audio.Device.BLUETOOTH_A2DP )
            };

            current_mode = FreeSmartphone.Audio.Mode.NORMAL;
            current_device = FreeSmartphone.Audio.Device.FRONTSPEAKER;

            router.set_device( current_device, false );
            router.set_mode( current_mode );

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

        public async FreeSmartphone.Audio.Device[] get_available_devices( FreeSmartphone.Audio.Mode mode )
            throws FreeSmartphone.Audio.Error, FreeSmartphone.Error, GLib.DBusError, GLib.IOError
        {
            return router.get_available_devices( mode );
        }

        public async FreeSmartphone.Audio.Mode get_mode()
            throws FreeSmartphone.Audio.Error, FreeSmartphone.Error, GLib.DBusError, GLib.IOError
        {
            return current_mode;
        }

        public async FreeSmartphone.Audio.Device get_device()
            throws FreeSmartphone.Audio.Error, FreeSmartphone.Error, GLib.DBusError, GLib.IOError
        {
            return current_device;
        }

        public async void set_mode( FreeSmartphone.Audio.Mode mode )
            throws FreeSmartphone.Audio.Error, FreeSmartphone.Error, GLib.DBusError, GLib.IOError
        {
            if ( mode == current_mode )
            {
                return;
            }

            assert( logger.debug( @"Switching mode: $(current_mode) -> $(mode)" ) );
            current_mode = mode;
            router.set_mode( current_mode );
            mode_changed( current_mode );
        }

        public async void set_device( FreeSmartphone.Audio.Device device )
            throws FreeSmartphone.Audio.Error, FreeSmartphone.Error, GLib.DBusError, GLib.IOError
        {
            // check wether the device is supported by our router
            var supported_devices = router.get_available_devices( current_mode );
            if ( !( device in supported_devices ) )
            {
                throw new FreeSmartphone.Error.UNSUPPORTED( "The supplied audio device is not supported by the current router" );
            }

            assert( logger.debug( @"Switching output device: $(current_device) -> $(device)" ) );

            current_device = device;
            router.set_device( current_device );
            device_changed( current_device );
        }

        public async void set_mute( FreeSmartphone.Audio.Control control, bool mute )
            throws FreeSmartphone.Error, GLib.DBusError, GLib.IOError
        {
            if ( devices[ current_device ].get_mute( current_mode, control ) )
            {
                return;
            }

            devices[ current_device ].set_mute( current_mode, control, mute );

            if ( mute )
            {
                router.set_volume( control, 0 );
            }
            else
            {
                var level = devices[ current_device ].get_volume( current_mode, control );
                router.set_volume( control, level );
            } 
        }

        public async bool get_mute( FreeSmartphone.Audio.Control control )
            throws FreeSmartphone.Error, GLib.DBusError, GLib.IOError
        {
            return devices[ current_device ].get_mute( current_mode, control );
        }


        public async void set_volume( FreeSmartphone.Audio.Control control, int volume )
            throws FreeSmartphone.Error, GLib.DBusError, GLib.IOError
        {
            if ( volume < 0 || volume > 100 )
            {
                throw new FreeSmartphone.Error.INVALID_PARAMETER( "Supplied volume level is out of range 0 - 100" );
            }

            devices[ current_device ].set_volume( current_mode, control, volume );
            if ( !devices[ current_device ].get_mute( current_mode, control ) )
            {
                router.set_volume( control, volume );
            }

            volume_changed( control, volume );
        }

        public async int get_volume( FreeSmartphone.Audio.Control control )
            throws FreeSmartphone.Error, GLib.DBusError, GLib.IOError
        {
            return devices[ current_device ].get_volume( current_mode, control );
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
