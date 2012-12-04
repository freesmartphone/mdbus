/*
 * Copyright (C) 2011-2012 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

namespace FsoAudio.GsmVoiceCmtspeechdata
{
    public const string MODULE_NAME = "fsoaudio.gsmvoice_alsa_cmtspeechdata";
}

class FsoAudio.GsmVoiceCmtspeechdata.Plugin : FsoFramework.AbstractObject
{
    private FsoFramework.Subsystem subsystem;
    private CmtHandler cmthandler;
    private FreeSmartphone.GSM.Call gsmcallproxy;

    //
    // Private API
    //
    private void onCallStatusSignal( int id, FreeSmartphone.GSM.CallStatus status, GLib.HashTable<string,Variant> properties )
    {
        assert( logger.debug( @"onCallStatusSignal $id w/ status $status" ) );
        switch ( status )
        {
            case FreeSmartphone.GSM.CallStatus.INCOMING:
            case FreeSmartphone.GSM.CallStatus.OUTGOING:
                cmthandler.setAudioStatus( true );
                break;

            case FreeSmartphone.GSM.CallStatus.RELEASE:
                cmthandler.setAudioStatus( false );
                break;

            default:
                assert( logger.debug( @"Unhandled call status $status" ) );
                break;
        }
    }

    //
    // Public API
    //
    public Plugin( FsoFramework.Subsystem subsystem )
    {
        this.subsystem = subsystem;
        cmthandler = new CmtHandler();

        try
        {
            gsmcallproxy = Bus.get_proxy_sync<FreeSmartphone.GSM.Call>( BusType.SYSTEM, "org.freesmartphone.ogsmd", "/org/freesmartphone/GSM/Device", DBusProxyFlags.DO_NOT_AUTO_START );
            gsmcallproxy.call_status.connect( onCallStatusSignal );
        }
        catch ( Error e )
        {
            logger.error( @"Could not hook to fsogsmd: $(e.message)" );
        }
    }

    public override string repr()
    {
        return "<>";
    }
}

internal FsoAudio.GsmVoiceCmtspeechdata.Plugin instance;

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    instance = new FsoAudio.GsmVoiceCmtspeechdata.Plugin( subsystem );
    return FsoAudio.GsmVoiceCmtspeechdata.MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsoaudio.gsmvoice_alsa_cmtspeechdata fso_register_function" );
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
