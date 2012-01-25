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
using FreeSmartphone.Audio;

namespace FsoAudio
{
    public static const string SESSIONPOLICY_DEFAULT_MODULE_NAME = "fsoaudio.sessionpolicy_default";

    // NOTE this needs to adjust when the number of streams in specs has changed. It's the
    // count of different streams we have without the INVALID one.
    private static const uint STREAM_COUNT = 5;

    public class DefaultSessionPolicy : AbstractSessionPolicy
    {
        private uint[] stream_usage;

        private delegate void StreamProcessFunc( FreeSmartphone.Audio.Stream stream );

        //
        // private API
        //

        private void resetStreamUsage()
        {
            for ( int n = 0; n < STREAM_COUNT; n++ )
            {
                stream_usage[n] = 0;
            }
        }

        private void processStreams( FreeSmartphone.Audio.Stream[] streams, StreamProcessFunc process_func )
        {
            foreach ( var stream in streams )
            {
                process_func( stream );
            }
        }

        private void handleDuckStatusForStream( Stream stream, Stream[] streamsToProcess )
        {
            if ( stream_usage[stream] > 0 )
            {
                processStreams( streamsToProcess, ( s ) => stream_control.set_mute( s, true ) );
            }
            else if ( stream_usage[stream] == 0 )
            {
                processStreams( streamsToProcess, ( s ) => stream_control.set_mute( s, false ) );
            }
        }

        private void updateStreamStatus()
        {
            // FIXME this should be read from the configuration file later!
            handleDuckStatusForStream( Stream.ALARM, new Stream[] { Stream.MEDIA, Stream.NAVIGATION, Stream.ALERT, Stream.RINGTONE } );
            handleDuckStatusForStream( Stream.RINGTONE, new Stream[] { Stream.MEDIA, Stream.NAVIGATION, Stream.ALERT } );
            handleDuckStatusForStream( Stream.ALERT, new Stream[] { Stream.MEDIA, Stream.NAVIGATION } );
            handleDuckStatusForStream( Stream.NAVIGATION, new Stream[] { Stream.MEDIA } );
        }

        //
        // public API
        //

        construct
        {
            stream_usage = new uint[STREAM_COUNT];
            resetStreamUsage();
        }

        public override void handleConnectingStream( Stream stream )
        {
            stream_usage[stream]++;
            updateStreamStatus();
        }

        public override void handleDisconnectingStream( Stream stream )
        {
            if ( stream_usage[stream] == 0 )
            {
                logger.error( @"Got info about a disconnecting stream but all streams of this type already have been disconnected!?" );
                return;
            }

            stream_usage[stream]--;
            updateStreamStatus();
        }
    }
}

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws GLib.Error
{
    return FsoAudio.SESSIONPOLICY_DEFAULT_MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsoaudio.sessionpolicy_default fso_register_function" );
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
