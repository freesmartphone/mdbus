/*
 * Copyright (C) 2011-2012 Simon Busch <morphis@gravedo.de>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

using GLib;

namespace FsoAudio
{
    public static const string STREAMCONTROL_ALSA_MODULE_NAME = "fsoaudio.streamcontrol_alsa";

    public class AlsaStreamDevice : FsoFramework.AbstractObject
    {
        private FreeSmartphone.Audio.Stream stream;
        private Alsa.PcmDevice device;

        private string stream_to_device_name( FreeSmartphone.Audio.Stream stream )
        {
            string result = "<unknown>";

            switch ( stream )
            {
                case FreeSmartphone.Audio.Stream.MEDIA:
                    result = "media";
                    break;
                case FreeSmartphone.Audio.Stream.ALERT:
                    result = "alert";
                    break;
                case FreeSmartphone.Audio.Stream.RINGTONE:
                    result = "ringtone";
                    break;
                case FreeSmartphone.Audio.Stream.ALARM:
                    result = "alarm";
                    break;
                case FreeSmartphone.Audio.Stream.NAVIGATION:
                    result = "navigation";
                    break;
                default:
                    break;
            }

            return result;
        }

        public AlsaStreamDevice( FreeSmartphone.Audio.Stream stream )
        {
            this.stream = stream;
        }


        public bool initialize()
        {
            string error_message = "";
            string device_name = stream_to_device_name( this.stream );

            int rc = Alsa.PcmDevice.open( out this.device, device_name, Alsa.PcmStream.PLAYBACK );
            if ( rc < 0 )
            {
                error_message = Alsa.strerror( rc );
                logger.error( @"Failed to initialize pcm device for stream $(this.stream): $(error_message)" );
                return false;
            }

            Alsa.PcmInfo info;
            Alsa.PcmInfo.malloc( out info );
            device.info( info );

            logger.debug( @"Initialized PCM device for stream $(stream) successfully!" );

            return true;
        }

        public void release()
        {
            string error_message = "";
            int rc = 0;

            if ( device == null )
            {
                logger.error( @"Can't close a not initialized device!" );
                return;
            }

            rc = device.close();
            if ( rc < 0 )
            {
                error_message = Alsa.strerror( rc );
                logger.error( @"Can't close pcm device for stream $(stream): $(error_message)" );
                return;
            }
        }

        public override string repr()
        {
            return "<>";
        }
    }

    public class StreamControlAlsa : AbstractStreamControl
    {
        private AlsaStreamDevice[] devices;

        public override void setup()
        {
            logger.debug("StreamControlAlsa::setup");

            devices = new AlsaStreamDevice[] {
                new AlsaStreamDevice( FreeSmartphone.Audio.Stream.MEDIA )
            };

            foreach ( var device in devices )
            {
                device.initialize();
            }
        }

        public override void set_mute( FreeSmartphone.Audio.Stream stream, bool mute )
        {
        }

        public override void set_volume( FreeSmartphone.Audio.Stream stream, uint level )
        {
        }

        public override bool get_mute( FreeSmartphone.Audio.Stream stream )
        {
            return false;
        }

        public override uint get_volume( FreeSmartphone.Audio.Stream stream )
        {
            return 100;
        }

    }
}

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    return FsoAudio.STREAMCONTROL_ALSA_MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsoaudio.streamcontrol_alsa fso_register_function" );
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
