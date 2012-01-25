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
using FsoFramework;

namespace FsoAudio
{
    const string SYSTEM_INTEGRATION_MODULE_NAME = "fsoaudio.system_integration";

    public class SystemIntegrator : AbstractObject
    {
        private FreeSmartphone.GSM.Call call_service;
        private FreeSmartphone.Audio.Manager audiomanager_service;
        private DBusServiceNotifier service_notifier;

        private bool ready;

        //
        // public API
        //

        public SystemIntegrator()
        {
            ready = false;
            service_notifier = new DBusServiceNotifier();

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
            assert( logger.debug( @"Switching audio mode to $mode" ) );

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

            assert( logger.debug( @"Got call status $(status)" ) );

            switch ( status )
            {
                case FreeSmartphone.GSM.CallStatus.OUTGOING:
                case FreeSmartphone.GSM.CallStatus.ACTIVE:
                    switchAudioMode( FreeSmartphone.Audio.Mode.CALL );
                    break;
                case FreeSmartphone.GSM.CallStatus.RELEASE:
                    switchAudioMode( FreeSmartphone.Audio.Mode.NORMAL );
                    break;
            }
        }

        private async void handleGSMServiceAppearing( string busname )
        {
            if ( busname != "org.freesmartphone.ogsmd" )
                return;

            try
            {
                call_service = yield Bus.get_proxy<FreeSmartphone.GSM.Call>( BusType.SYSTEM,
                    "org.freesmartphone.ogsmd", "/org/freesmartphone/GSM/Device", DBusProxyFlags.DO_NOT_AUTO_START);
                call_service.call_status.connect( ( id, status, properties ) => { handleCallStatus( status ); } );
            }
            catch ( GLib.Error error )
            {
                logger.error( @"Could not get proxy object for call service: $(error.message)" );
            }

            ready = ( call_service != null );
        }

        private async void handleGSMServiceDisappearing( string busname )
        {
            if ( busname != "org.freesmartphone.ogsmd" )
                return;

            call_service = null;
            ready = false;
        }

        private async void registerObjects()
        {
            try
            {
                assert( logger.debug( @"Started registration process with call service ..." ) );

                // NOTE: it should be always possible to connect to the audio manager
                // service as it is provided by us
                audiomanager_service = yield Bus.get_proxy<FreeSmartphone.Audio.Manager>( BusType.SYSTEM,
                    "org.freesmartphone.oaudiod", "/org/freesmartphone/Audio", DBusProxyFlags.DO_NOT_AUTO_START);

                call_service = yield Bus.get_proxy<FreeSmartphone.GSM.Call>( BusType.SYSTEM,
                    "org.freesmartphone.ogsmd", "/org/freesmartphone/GSM/Device", DBusProxyFlags.DO_NOT_AUTO_START);
                call_service.call_status.connect( ( id, status, properties ) => { handleCallStatus( status ); } );

                // call service is not yet started, we need to wait until it is.
                service_notifier.notifyAppearing( "org.freesmartphone.ogsmd",
                    ( busname ) => { handleGSMServiceAppearing( busname ); } );
                service_notifier.notifyDisappearing( "org.freesmartphone.ogsmd",
                    ( busname ) => { handleGSMServiceDisappearing( busname ); } );

                ready = ( call_service != null );

                if ( ready )
                {
                    assert( logger.debug( @"Successfully registered with call service!" ) );
                }
            }
            catch ( GLib.Error error )
            {
                logger.error( @"Could not create dbus proxies for relevant interfaces: $(error.message)" );
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
