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

namespace FsoAudio
{
    const string SYSTEM_INTEGRATION_MODULE_NAME = "fsoaudio.system_integration";

    public class SystemIntegrator : AbstractObject
    {
        private FreeSmartphone.GSM.Call call_service;
        private FreeSmartphone.Audio.Manager audiomanager_service;

        private bool ready;

        //
        // public API
        //

        public SystemIntegrator()
        {
            ready = false;
            Idle.add( () => { registerObjects(); return false; } );
        }

        public override string repr()
        {
            return "<>";
        }

        //
        // private
        //

        private async void switchAudioMode( FreeSmartphone.Audio.Mode mode )
        {
            try
            {
                yield audiomanager_service.set_mode( mode );
            }
            catch ( GLib.Error error )
            {
                logger.error( @"Could not set audio mode to $mode: $(error.message)" );
            }
        }

        /**
         * When the status of call switches to active or release we need to set the audio
         * mode according to this.
         **/
        private async void handleCallStatus( FreeSmartphone.GSM.CallStatus status )
        {
            if ( !ready )
            {
                logger.warning( @"Not yet ready to handle call status $status" );
                return;
            }

            switch ( status )
            {
                case FreeSmartphone.GSM.CallStatus.ACTIVE:
                    switchAudioMode( FreeSmartphone.Audio.Mode.CALL );
                    break;
                case FreeSmartphone.GSM.CallStatus.RELEASE:
                    switchAudioMode( FreeSmartphone.Audio.Mode.NORMAL );
                    break;
            }
        }

        private async void registerObjects()
        {
            try
            {
                call_service = Bus.get_proxy_sync<FreeSmartphone.GSM.Call>( BusType.SYSTEM,
                    "org.freesmartphone.ogsmd", "/org/freesmartphone/GSM/Device" );
                call_service.call_status.connect( ( id, status, properties ) => { handleCallStatus( status ); } );

                audiomanager_service = Bus.get_proxy_sync<FreeSmartphone.Audio.Manager>( BusType.SYSTEM,
                    "org.freesmartphone.oaudiod", "/org/freesmartphone/Audio" );

                ready = true;
                logger.debug( "Successfully initialized!" );
            }
            catch ( GLib.Error error )
            {
                logger.error( "Could not create dbus proxies for relevant interfaces: $(error.message)" );
            }
        }
    }
}

internal FsoAudio.SystemIntegrator instance;

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    instance = new FsoAudio.SystemIntegrator();
    return FsoAudio.SYSTEM_INTEGRATION_MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsoaudio.system_integration fso_register_function" );
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
