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

const string ROUTER_PALMPRE_SCRIPT_BASE_PATH = "/etc/audio/scripts";
const string ROUTER_PALMPRE_SCRUN_PATH = "/sys/devices/platform/twl4030_audio/scrun";
const string ROUTER_PALMPRE_SCINIT_PATH = "/sys/devices/platform/twl4030_audio/scinit";

namespace FsoAudio
{
    public static const string ROUTER_PALMPRE_MODULE_NAME = "fsoaudio.router_palmpre";

    const string ROUTER_PALMPRE_SCRIPT_BASE_PATH = "/etc/audio/scripts";
    const string ROUTER_PALMPRE_SCRUN_PATH = "/sys/devices/platform/twl4030_audio/scrun";
    const string ROUTER_PALMPRE_SCINIT_PATH = "/sys/devices/platform/twl4030_audio/scinit";

    private class KernelScriptInterface
    {
        public static void loadAndStoreScriptFromFile(string filename)
        {
            if (FsoFramework.FileHandling.isPresent(filename))
            {
                FsoFramework.theLogger.debug( @"loading audio script from '$(filename)'" );
                string script = FsoFramework.FileHandling.read(filename);
                FsoFramework.FileHandling.write(script, ROUTER_PALMPRE_SCINIT_PATH);
            }
        }

        public static void runScript(string script_name)
        {
            FsoFramework.theLogger.debug( @"executing audio script '$(script_name)'" );
            FsoFramework.FileHandling.write(script_name, ROUTER_PALMPRE_SCRUN_PATH);
        }
    }
}

public class Router.PalmPre : FsoAudio.AbstractRouter
{
    construct
    {
        normal_supported_devices = new FreeSmartphone.Audio.Device[] {
            FreeSmartphone.Audio.Device.BACKSPEAKER,
            FreeSmartphone.Audio.Device.FRONTSPEAKER,
            FreeSmartphone.Audio.Device.HEADSET,
            FreeSmartphone.Audio.Device.BLUETOOTH_A2DP
        };

        call_supported_devices = new FreeSmartphone.Audio.Device[] {
            FreeSmartphone.Audio.Device.BACKSPEAKER,
            FreeSmartphone.Audio.Device.FRONTSPEAKER,
            FreeSmartphone.Audio.Device.HEADSET,
            FreeSmartphone.Audio.Device.BLUETOOTH_SCO
        };

        string[] scripts = new string[] {
            "default",
            "dtmf",
            "media_back_speaker",
            "media_front_speaker",
            "media_headset",
            "media_bluetooth_a2dp",
            "phone_back_speaker",
            "phone_front_speaker",
            "phone_headset",
            "phone_bluetooth_sco" 
        };

        foreach ( var script in scripts )
        {
            var path = @"$(FsoAudio.ROUTER_PALMPRE_SCRIPT_BASE_PATH)/$(script).txt";
            FsoAudio.KernelScriptInterface.loadAndStoreScriptFromFile( path );
        }

        logger.info( @"Created and configured." );
    }

    private string retrieveScriptPrefix()
    {
        string prefix = "";

        switch ( current_mode )
        {
            case FreeSmartphone.Audio.Mode.NORMAL:
                prefix = "media_";
                break;
            case FreeSmartphone.Audio.Mode.CALL:
                prefix = "phone_";
                break;
        }

        switch ( current_device )
        {
            case FreeSmartphone.Audio.Device.BACKSPEAKER:
                prefix += "back_speaker";
                break;
            case FreeSmartphone.Audio.Device.FRONTSPEAKER:
                prefix += "front_speaker";
                break;
            case FreeSmartphone.Audio.Device.HEADSET:
                prefix += "headset";
                break;
            case FreeSmartphone.Audio.Device.BLUETOOTH_SCO:
                prefix += "bluetooth_sco";
                break;
            case FreeSmartphone.Audio.Device.BLUETOOTH_A2DP:
                prefix += "bluetooth_a2dp";
                break;
        }

        return prefix;
    }

    public override string repr()
    {
        return "<>";
    }

    public override void set_mode( FreeSmartphone.Audio.Mode mode, bool force = false )
    {
        if ( !force && mode == current_mode )
        {
            return;
        }

        var previous_mode = current_mode;
        base.set_mode( mode );

        // Check wether a call scenario as started or ended
        if ( previous_mode == FreeSmartphone.Audio.Mode.NORMAL && 
             current_mode == FreeSmartphone.Audio.Mode.CALL )
        {
            FsoAudio.KernelScriptInterface.runScript( "call_started" );
        }
        else if ( previous_mode == FreeSmartphone.Audio.Mode.CALL &&
                  current_mode == FreeSmartphone.Audio.Mode.NORMAL )
        {
            FsoAudio.KernelScriptInterface.runScript( "call_ended" );
        }

        // Route correctly to current output device
        FsoAudio.KernelScriptInterface.runScript( retrieveScriptPrefix() );
    }

    public override void set_device( FreeSmartphone.Audio.Device device, bool expose = true )
    {
        base.set_device( device, expose );

        if ( !expose )
        {
            return;
        }

        var script_name = retrieveScriptPrefix();
        FsoAudio.KernelScriptInterface.runScript( script_name );
    }

    public override void set_volume( FreeSmartphone.Audio.Control control, uint volume )
    {
        var base_name = retrieveScriptPrefix();

        // NOTE: we ignore the control type here completly as we don't have a method to
        // adjust the volume for different controls ...

        if ( current_mode == FreeSmartphone.Audio.Mode.NORMAL )
        {
            // FIXME we currently cannot adjust the volume in normal media playback mode
        }
        else if ( current_mode == FreeSmartphone.Audio.Mode.CALL )
        {
            var level = volume / 10;
            var script_name = @"$(base_name)_volume_$(level)";
            FsoAudio.KernelScriptInterface.runScript( script_name );
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
    return FsoAudio.ROUTER_PALMPRE_MODULE_NAME;
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

// vim:ts=4:sw=4:expandtab
