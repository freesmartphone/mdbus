/*
 * Copyright (C) 2009-2012 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *                         Simon Busch <morphis@gravedo.de>
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
    public static const string ROUTER_ALSA_MODULE_NAME = "fsoaudio.router_alsa";
}

public class Router.LibAlsa : FsoAudio.AbstractRouter
{
    private FsoAudio.SoundDevice device;
    private Gee.HashMap<string,FsoAudio.BunchOfMixerControls> allscenarios;
    private Gee.HashMap<FreeSmartphone.Audio.Device,string> normalDeviceScenarios;
    private Gee.HashMap<FreeSmartphone.Audio.Device,string> callDeviceScenarios;

    private string configurationPath;
    private string dataPath;
    private string currentscenario;

    construct
    {
        initScenarios();

        logger.info( @"Created and configured." );
    }

    private void addScenario( string scenario, File file, uint idxSpeakerVolume, uint idxMicVolume )
    {
        FsoAudio.MixerControl[] controls = {};

        try
        {
            // Open file for reading and wrap returned FileInputStream into a
            // DataInputStream, so we can read line by line
            var in_stream = new DataInputStream( file.read( null ) );
            string line;
            // Read lines until end of file (null) is reached
            while ( ( line = in_stream.read_line( null, null ) ) != null )
            {
                var stripped = line.strip();
                if ( stripped == "" || stripped.has_prefix( "#" ) ) // skip empty lines and comments
                    continue;
                var control = device.controlForString( line );
                controls += control;
            }
#if DEBUG
            debug( "Scenario %s successfully read from file %s".printf( scenario, file.get_path() ) );
#endif
            var bunch = new FsoAudio.BunchOfMixerControls( controls, idxSpeakerVolume, idxMicVolume );
            allscenarios[scenario] = bunch;
        }
        catch ( IOError e )
        {
            FsoFramework.theLogger.warning( "%s".printf( e.message ) );
        }
    }

    private Gee.HashMap<FreeSmartphone.Audio.Device,string> readDeviceScenarios( FsoFramework.SmartKeyFile alsaconf, GLib.List<string> sections )
    {
        var result = new Gee.HashMap<FreeSmartphone.Audio.Device,string>();

        foreach ( var section in sections )
        {
            var device_name = section.split( "." )[1];
            if ( device_name != "" )
            {
                var scenario = alsaconf.stringValue( section, "scenario", "" );
                var idxSpeakerVolume = alsaconf.intValue( section, "speaker_volume", 0 );
                var idxMicVolume = alsaconf.intValue( section, "mic_volume", 0 );

                assert( FsoFramework.theLogger.debug( "Found scenario '%s' - speaker volume = %d, mic volume = %d".printf( scenario, idxSpeakerVolume, idxMicVolume ) ) );

                var file = File.new_for_path( Path.build_filename( dataPath, scenario ) );
                if ( !file.query_exists(null) )
                {
                    FsoFramework.theLogger.warning( @"Scenario file $(file.get_path()) doesn't exist. Ignoring." );
                }
                else
                {
                    addScenario( scenario, file, idxSpeakerVolume, idxMicVolume );

                    var device_type = FsoFramework.StringHandling.enumFromNick<FreeSmartphone.Audio.Device>( device_name );
                    result.set( device_type, scenario );
                }
            }
        }

        return result;
    }

    private FreeSmartphone.Audio.Device[] buildDeviceList( Gee.HashMap<FreeSmartphone.Audio.Device,string> deviceMap )
    {
        FreeSmartphone.Audio.Device[] devices =  new FreeSmartphone.Audio.Device[] { };

        foreach ( var device in deviceMap.keys )
        {
            devices += device;
        }

        return devices;
    }

    private void initScenarios()
    {
        GLib.List<string> sections;

        configurationPath = FsoFramework.Utility.machineConfigurationDir() + "/alsa.conf";
        allscenarios = new Gee.HashMap<string,FsoAudio.BunchOfMixerControls>();
        currentscenario = "unknown";

        // init scenarios
        FsoFramework.SmartKeyFile alsaconf = new FsoFramework.SmartKeyFile();
        if ( alsaconf.loadFromFile( configurationPath ) )
        {
            var soundcard = alsaconf.stringValue( "alsa", "cardname", "default" );
            dataPath = FsoFramework.Utility.machineConfigurationDir() + @"/alsa-$soundcard";

            try
            {
                device = FsoAudio.SoundDevice.create( soundcard );
            }
            catch ( FsoAudio.SoundError e )
            {
                FsoFramework.theLogger.warning( @"Sound card problem: $(e.message)" );
                return;
            }

            sections = alsaconf.sectionsWithPrefix( "normal." );
            normalDeviceScenarios = readDeviceScenarios( alsaconf, sections );
            normal_supported_devices = buildDeviceList( normalDeviceScenarios );

            sections = alsaconf.sectionsWithPrefix( "call." );
            callDeviceScenarios = readDeviceScenarios( alsaconf, sections );
            call_supported_devices = buildDeviceList( callDeviceScenarios );

            // listen for changes for alsa configuration
            FsoFramework.INotifier.add( dataPath, Linux.InotifyMaskFlags.MODIFY, onModifiedScenario );
        }
        else
        {
            FsoFramework.theLogger.warning( @"Could not load $configurationPath. No scenarios available." );

            // try to set sane default state; use "default" as soundcard and current values as default scenario
            try
            {
                device = FsoAudio.SoundDevice.create( "default" );
            }
            catch ( FsoAudio.SoundError e )
            {
                FsoFramework.theLogger.warning( @"Sound card problem: $(e.message)" );
                return;
            }
            var bunch = new FsoAudio.BunchOfMixerControls( device.allMixerControls() );
            allscenarios["current"] = bunch;
            currentscenario = "current";
        }
    }

    private void updateScenarioIfChanged( string scenario )
    {
        if ( currentscenario != scenario )
        {
            assert( device != null );
            device.setAllMixerControls( allscenarios[scenario].controls );

            currentscenario = scenario;
        }
    }

    private void onModifiedScenario( Linux.InotifyMaskFlags flags, uint32 cookie, string? name )
    {
#if DEBUG
        debug( "onModifiedScenario: %s", name );
#endif
        assert( name != null );

        if ( ! ( name in allscenarios ) )
        {
            assert( FsoFramework.theLogger.debug( @"$name is not a recognized scenario. Ignoring" ) );
            return;
        }

        var idxSpeakerVolume = allscenarios[name].idxSpeakerVolume;
        var idxMicVolume = allscenarios[name].idxMicVolume;

        if ( name == currentscenario )
        {
            FsoFramework.theLogger.info( @"Scenario $name has been changed (being also the current scenario); invalidating cache and reloading" );
            var file = File.new_for_path( Path.build_filename( dataPath, name ) );
            if ( !file.query_exists(null) )
            {
                FsoFramework.theLogger.warning( @"Scenario file $(file.get_path()) doesn't exist. Ignoring." );
            }
            else
            {
                addScenario( name, file, idxSpeakerVolume, idxMicVolume );
                device.setAllMixerControls( allscenarios[name].controls );
            }
        }
        else
        {
            FsoFramework.theLogger.info( @"Scenario $name has been changed; invalidating cache for this." );
            // save current one
            var scene = new FsoAudio.BunchOfMixerControls( device.allMixerControls() );
            // reload changed one from disk
            var file = File.new_for_path( Path.build_filename( dataPath, name ) );
            if ( !file.query_exists(null) )
            {
                FsoFramework.theLogger.warning( @"Scenario file $(file.get_path()) doesn't exist. Ignoring." );
            }
            else
            {
                addScenario( name, file, idxSpeakerVolume, idxMicVolume );
            }
            // restore saved one
            device.setAllMixerControls( scene.controls );
        }
    }

    private string retrieveScenarioForDevice( FreeSmartphone.Audio.Device device )
    {
        string scenario = "unknown";

        if ( current_mode == FreeSmartphone.Audio.Mode.NORMAL )
        {
            if ( callDeviceScenarios.has_key( device ) )
            {
                scenario = normalDeviceScenarios[ device ];
            }
        }
        else if ( current_mode == FreeSmartphone.Audio.Mode.CALL )
        {
            if ( callDeviceScenarios.has_key( device ) )
            {
                scenario = callDeviceScenarios[ device ];
            }
        }

        return scenario;
    }

    private bool setScenarioForDevice( FreeSmartphone.Audio.Device device )
    {
        bool result = false;

        string scenario = retrieveScenarioForDevice( device );
        if ( scenario != "unknown" )
        {
            updateScenarioIfChanged( scenario );
            result = true;
        }

        return result;
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
        if ( !setScenarioForDevice( current_device ) )
        {
            // Something went terrible wrong ... maybe device is not supported in the new
            // mode. Anyway we will switch back to old mode now.
            logger.error( @"Could not switch to new mode $(mode); switching back to old mode $(previous_mode) ..." );
            set_mode( previous_mode );
        }
    }

    public override void set_device( FreeSmartphone.Audio.Device device, bool expose = true )
    {
        if ( device == current_device )
        {
            return;
        }

        base.set_device( device, expose );

        if ( !expose )
        {
            return;
        }

        setScenarioForDevice( device );
    }

    public override void set_volume( FreeSmartphone.Audio.Control control, uint volume )
    {
        var scenario = allscenarios[currentscenario];
        assert( scenario != null );

        var idx = control == FreeSmartphone.Audio.Control.SPEAKER ? scenario.idxSpeakerVolume : scenario.idxMicVolume;
        device.setVolumeForIndex( idx, (uint8) volume );
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
    return FsoAudio.ROUTER_ALSA_MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsoaudio.router_alsa fso_register_function" );
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
