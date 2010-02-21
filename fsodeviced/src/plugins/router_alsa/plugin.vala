/**
 * Copyright (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

using Gee;

namespace Router
{

/**
 * Alsa Scenario Router
 **/
class LibAlsa : FsoDevice.BaseAudioRouter
{
    private const string MODULE_NAME = "fsodevice.router_alsa";

    private FsoFramework.SoundDevice device;
    private HashMap<string,FsoFramework.BunchOfMixerControls> allscenarios;
    private string currentscenario;
    private GLib.Queue<string> scenarios;

    private string configurationPath;
    private string dataPath;

    construct
    {
        initScenarios();
        if ( currentscenario != "unknown" )
        {
            device.setAllMixerControls( allscenarios[currentscenario].controls );
        }
    }

    private void addScenario( string scenario, File file )
    {
        FsoFramework.MixerControl[] controls = {};

        try
        {
            // Open file for reading and wrap returned FileInputStream into a
            // DataInputStream, so we can read line by line
            var in_stream = new DataInputStream( file.read( null ) );
            string line;
            // Read lines until end of file (null) is reached
            while ( ( line = in_stream.read_line( null, null ) ) != null )
            {
                var control = device.controlForString( line );
                controls += control;
            }
#if DEBUG
            debug( "Scenario %s successfully read from file %s".printf( scenario, file.get_path() ) );
#endif
            var bunch = new FsoFramework.BunchOfMixerControls( controls );
            allscenarios[scenario] = bunch;
        }
        catch ( IOError e )
        {
            FsoFramework.theLogger.warning( "%s".printf( e.message ) );
        }
    }

    private void initScenarios()
    {
        configurationPath = FsoFramework.Utility.machineConfigurationDir() + "/alsa.conf";

        scenarios = new GLib.Queue<string>();
        allscenarios = new HashMap<string,FsoFramework.BunchOfMixerControls>( str_hash, str_equal );
        currentscenario = "unknown";

        // init scenarios
        FsoFramework.SmartKeyFile alsaconf = new FsoFramework.SmartKeyFile();
        if ( alsaconf.loadFromFile( configurationPath ) )
        {
            var soundcard = alsaconf.stringValue( "alsa", "cardname", "default" );
            dataPath = FsoFramework.Utility.machineConfigurationDir() + @"/alsa-$soundcard";

            try
            {
                device = FsoFramework.SoundDevice.create( soundcard );
            }
            catch ( FsoFramework.SoundError e )
            {
                FsoFramework.theLogger.warning( @"Sound card problem: $(e.message)" );
                return;
            }
            var defaultscenario = alsaconf.stringValue( "alsa", "default_scenario", "stereoout" );

            var sections = alsaconf.sectionsWithPrefix( "scenario." );
            foreach ( var section in sections )
            {
                var scenario = section.split( "." )[1];
                if ( scenario != "" )
                {
                    FsoFramework.theLogger.debug( "Found scenario '%s'".printf( scenario ) );

                    var file = File.new_for_path( Path.build_filename( dataPath, scenario ) );
                    if ( !file.query_exists(null) )
                    {
                        FsoFramework.theLogger.warning( @"Scenario file $(file.get_path()) doesn't exist. Ignoring." );
                    }
                    else
                    {
                        addScenario( scenario, file );
                    }
                }
            }

            if ( defaultscenario in allscenarios )
            {
                pushScenario( defaultscenario ); // ASYNC
            }
            else
            {
                FsoFramework.theLogger.warning( "Default scenario not found; can't push it to scenario stack" );
            }
            // listen for changes
            FsoFramework.INotifier.add( dataPath, Linux.InotifyMaskFlags.MODIFY, onModifiedScenario );
        }
        else
        {
            FsoFramework.theLogger.warning( @"Could not load $dataPath. No scenarios available." );
        }
    }

    private void updateScenarioIfChanged( string scenario )
    {
        if ( currentscenario != scenario )
        {
            assert( device != null );
            device.setAllMixerControls( allscenarios[scenario].controls );

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
            assert( FsoFramework.theLogger.debug( @"$name is not a recognized scenario. Ignoring" ) );
            return;
        }

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
                addScenario( name, file );
                device.setAllMixerControls( allscenarios[name].controls );
            }
        }
        else
        {
            FsoFramework.theLogger.info( @"Scenario $name has been changed; invalidating cache for this." );
            // save current one
            var scene = new FsoFramework.BunchOfMixerControls( device.allMixerControls() );
            // reload changed one from disk
            var file = File.new_for_path( Path.build_filename( dataPath, name ) );
            if ( !file.query_exists(null) )
            {
                FsoFramework.theLogger.warning( @"Scenario file $(file.get_path()) doesn't exist. Ignoring." );
            }
            else
            {
                addScenario( name, file );
            }
            // restore saved one
            device.setAllMixerControls( scene.controls );
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

    public override void saveScenario( string scenario )
    {
        var scene = new FsoFramework.BunchOfMixerControls( device.allMixerControls() );
        var filename = Path.build_filename( dataPath, scenario );
        FsoFramework.FileHandling.write( scene.to_string(), filename );
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
