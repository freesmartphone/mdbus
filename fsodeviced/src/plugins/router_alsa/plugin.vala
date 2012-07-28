/*
 * Copyright (C) 2009-2012 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

namespace Router
{

/**
 * Alsa Scenario Router
 **/
class LibAlsa : FsoDevice.BaseAudioRouter
{
    private const string MODULE_NAME = "fsodevice.router_alsa";

    private FsoDevice.SoundDevice device;
    private Gee.HashMap<string,FsoDevice.BunchOfMixerControls> allscenarios;
    private string currentscenario;
    private GLib.Queue<string> scenarios;

    private string configurationPath;
    private string dataPath;

    construct
    {
        initScenarios();
        if ( currentscenario != "unknown" )
        {
            try
            {
                device.setAllMixerControls( allscenarios[currentscenario].controls );
            }
            catch ( FsoDevice.SoundError e )
            {
                logger.warning( @"Setting mixer controls for scenario $currentscenario failed: $(e.message)" );
            }
        }
    }

    private void addScenario( string scenario, File file, uint idxMainVolume )
    {
        FsoDevice.MixerControl[] controls = {};
        int line_count = 0;

        try
        {
            // Open file for reading and wrap returned FileInputStream into a
            // DataInputStream, so we can read line by line
            var in_stream = new DataInputStream( file.read( null ) );
            string line;
            // Read lines until end of file (null) is reached
            while ( ( line = in_stream.read_line( null, null ) ) != null )
            {
                line_count++;

                var stripped = line.strip();
                if ( stripped == "" || stripped.has_prefix( "#" ) ) // skip empty lines and comments
                    continue;
                try
                {
                    var control = device.controlForString( line );
                    controls += control;
                }
                catch ( FsoDevice.SoundError e )
                {
                    logger.error( @"Got error while parsing line $line_count of scenario $scenario:" );
                    logger.error( @"$(e.message)" );
                }
            }

            logger.debug( "Scenario %s successfully read from file %s".printf( scenario, file.get_path() ) );

            var bunch = new FsoDevice.BunchOfMixerControls( controls, idxMainVolume );
            allscenarios[scenario] = bunch;
        }
        catch ( Error e )
        {
            logger.warning( @"$(e.message)" );
        }
    }

    private void initScenarios()
    {
        configurationPath = FsoFramework.Utility.machineConfigurationDir() + "/alsa.conf";

        scenarios = new GLib.Queue<string>();
        allscenarios = new Gee.HashMap<string,FsoDevice.BunchOfMixerControls>();
        currentscenario = "unknown";

        // init scenarios
        FsoFramework.SmartKeyFile alsaconf = new FsoFramework.SmartKeyFile();
        if ( alsaconf.loadFromFile( configurationPath ) )
        {
            var soundcard = alsaconf.stringValue( "alsa", "cardname", "default" );
            dataPath = FsoFramework.Utility.machineConfigurationDir() + @"/alsa-$soundcard";

            try
            {
                device = FsoDevice.SoundDevice.create( soundcard );
            }
            catch ( FsoDevice.SoundError e )
            {
                logger.warning( @"Sound card problem: $(e.message)" );
                return;
            }
            var defaultscenario = alsaconf.stringValue( "alsa", "default_scenario", "stereoout" );

            var sections = alsaconf.sectionsWithPrefix( "scenario." );
            foreach ( var section in sections )
            {
                var scenario = section.split( "." )[1];
                if ( scenario != "" )
                {
                    var idxMainVolume = alsaconf.intValue( section, "main_volume", 0 );
                    logger.debug( "Found scenario '%s' - main volume = %d".printf( scenario, idxMainVolume ) );

                    var file = File.new_for_path( Path.build_filename( dataPath, scenario ) );
                    if ( !file.query_exists(null) )
                    {
                        logger.warning( @"Scenario file $(file.get_path()) doesn't exist. Ignoring." );
                    }
                    else
                    {
                        addScenario( scenario, file, idxMainVolume );
                    }
                }
            }

            if ( defaultscenario in allscenarios )
            {
                pushScenario( defaultscenario ); // ASYNC
            }
            else
            {
                logger.warning( "Default scenario not found; can't push it to scenario stack" );
            }
            // listen for changes
            FsoFramework.INotifier.add( dataPath, Linux.InotifyMaskFlags.MODIFY, onModifiedScenario );
        }
        else
        {
            logger.warning( @"Could not load $configurationPath. No scenarios available." );
            // try to set sane default state; use "default" as soundcard and current values as default scenario
            try
            {
                device = FsoDevice.SoundDevice.create( "default" );
                var bunch = new FsoDevice.BunchOfMixerControls( device.allMixerControls() );
                allscenarios["current"] = bunch;
                currentscenario = "current";
            }
            catch ( FsoDevice.SoundError e )
            {
                logger.warning( @"Sound card or mixer problem: $(e.message)" );
            }
        }
    }

    private void updateScenarioIfChanged( string scenario )
    {
        if ( currentscenario != scenario )
        {
            assert( device != null );
            try
            {
                device.setAllMixerControls( allscenarios[scenario].controls );
            }
            catch ( FsoDevice.SoundError e )
            {
                logger.warning( @"Failed to update scenario '$scenario' to get changes: $(e.message)" );
            }

            currentscenario = scenario;
            //this.scenario( currentscenario, "N/A" ); // DBUS SIGNAL
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
            assert( logger.debug( @"$name is not a recognized scenario. Ignoring" ) );
            return;
        }

        var idxMainVolume = allscenarios[name].idxMainVolume;

        if ( name == currentscenario )
        {
            logger.info( @"Scenario $name has been changed (being also the current scenario); invalidating cache and reloading" );
            var file = File.new_for_path( Path.build_filename( dataPath, name ) );
            if ( !file.query_exists( null ) )
            {
                logger.warning( @"Scenario file $(file.get_path()) doesn't exist. Ignoring." );
            }
            else
            {
                addScenario( name, file, idxMainVolume );
                try
                {
                    device.setAllMixerControls( allscenarios[name].controls );
                }
                catch ( FsoDevice.SoundError e )
                {
                    logger.warning( @"Failed to set mixer controls for scenario $name: $(e.message)" );
                }
            }
        }
        else
        {
            logger.info( @"Scenario $name has been changed; invalidating cache for this." );
            try
            {
                // save current one
                var scene = new FsoDevice.BunchOfMixerControls( device.allMixerControls() );
                // reload changed one from disk
                var file = File.new_for_path( Path.build_filename( dataPath, name ) );
                if ( !file.query_exists(null) )
                {
                    logger.warning( @"Scenario file $(file.get_path()) doesn't exist. Ignoring." );
                }
                else
                {
                    addScenario( name, file, idxMainVolume );
                }
                // restore saved one
                device.setAllMixerControls( scene.controls );
            }
            catch ( FsoDevice.SoundError e )
            {
                logger.warning( @"Failed invalidating scenario $name: $(e.message)" );
            }
        }
    }

    public override bool isScenarioAvailable( string scenario )
    {
        return ( scenario in allscenarios.keys );
    }

    public override string[] availableScenarios()
    {
        string[] list = {};
        foreach ( var key in allscenarios.keys )
            list += key;
        return list;
    }

    public override string currentScenario()
    {
        return currentscenario;
    }

    public override string pullScenario() throws FreeSmartphone.Device.AudioError
    {
        scenarios.pop_head();
        var scenario = scenarios.peek_head();
        if ( scenario == null )
        {
            throw new FreeSmartphone.Device.AudioError.SCENARIO_STACK_UNDERFLOW( "No scenario left to activate" );
        }
        setScenario( scenario );
        return scenario;
    }

    public override void pushScenario( string scenario )
    {
        setScenario( scenario );
        scenarios.push_head( scenario );
    }

    public override void setScenario( string scenario )
    {
        updateScenarioIfChanged( scenario );
    }

    public override void saveScenario( string scenario ) throws FreeSmartphone.Error
    {
        if ( !allscenarios.has_key( scenario ) )
            throw new FreeSmartphone.Error.INVALID_PARAMETER( @"Can't save a unknown scenario" );

        try
        {
            var scenario_controls = new FsoDevice.BunchOfMixerControls( allscenarios[scenario].controls );
            var filename = Path.build_filename( dataPath, scenario );
            FsoFramework.FileHandling.write( scenario_controls.to_string(), filename );
        }
        catch ( Error e )
        {
            logger.warning( @"Saving scenario $scenario failed: $(e.message)" );
        }
    }

    public override uint8 currentVolume() throws FreeSmartphone.Error
    {
        var scenario = allscenarios[currentscenario];
        assert( scenario != null );

        return device.volumeForIndex( scenario.idxMainVolume );
    }

    public override void setVolume( uint8 volume ) throws FreeSmartphone.Error
    {
        var scenario = allscenarios[currentscenario];
        assert( scenario != null );
        device.setVolumeForIndex( scenario.idxMainVolume, volume );
    }

    public override string repr()
    {
        return @"<>";
    }
}

} /* namespace Router */

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    // instances will be created on demand by fsodevice.audio
    return "fsodevice.router_alsa";
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsodevice.router_alsa fso_register_function()" );
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
