/**
 * Copyright (C) 2009 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

const string FSO_ALSA_CONF_PATH = "/etc/freesmartphone/alsa/default.conf";
const string FSO_ALSA_DATA_PATH = "/etc/freesmartphone/alsa/default/";

namespace Alsa
{

/**
 * Alsa Audio Player
 **/
class AudioPlayer : FreeSmartphone.Device.Audio, FsoFramework.AbstractObject
{
    private const string MODULE_NAME = "fsodevice.alsa_audio";

    private FsoFramework.Subsystem subsystem;
    private FsoFramework.SoundDevice device;
    private HashMap<string,FsoFramework.BunchOfMixerControls> allscenarios;
    private string currentscenario;
    private GLib.Queue<string> scenarios;

    private FsoDevice.AudioPlayer player;
    private string typename;

    public AudioPlayer( FsoFramework.Subsystem subsystem )
    {
        this.subsystem = subsystem;

        subsystem.registerServiceName( FsoFramework.Device.ServiceDBusName );
        subsystem.registerServiceObject( FsoFramework.Device.ServiceDBusName,
                                         FsoFramework.Device.AudioServicePath,
                                         this );

        // gather requested player type and instanciate object
        var playername = config.stringValue( MODULE_NAME, "player_type", "unknown" );
        typename = "";

        switch ( playername )
        {
            case "alsa":
                typename = "PlayerLibAlsa";
                break;
            case "canberra":
                typename = "PlayerLibCanberra";
                break;
            default:
                typename = "PlayerUnknown";
                break;
        }
        var playertyp = GLib.Type.from_name( typename );
        if ( playertyp == GLib.Type.INVALID )
        {
            logger.warning( @"Can't instanciate player type $typename; will not be able to play audio" );
            player = new FsoDevice.NullPlayer();
            typename = "NullPlayer";
        }
        else
        {
            player = (FsoDevice.AudioPlayer) GLib.Object.new( playertyp );
        }

        // init scenarios
        initScenarios();
        if ( currentscenario != "unknown" )
        {
            device.setAllMixerControls( allscenarios[currentscenario].controls );
        }
        scenarios = new GLib.Queue<string>();

        logger.info( "created." );
    }

    public override string repr()
    {
        return @"<$typename>";
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
            logger.debug( "Scenario %s successfully read from file %s".printf( scenario, file.get_path() ) );
            var bunch = new FsoFramework.BunchOfMixerControls( controls );
            allscenarios[scenario] = bunch;
        }
        catch (IOError e)
        {
            logger.error( "%s".printf( e.message ) );
        }
    }

    private void initScenarios()
    {
        allscenarios = new HashMap<string,FsoFramework.BunchOfMixerControls>( str_hash, str_equal );
        currentscenario = "unknown";

        // init scenarios
        FsoFramework.SmartKeyFile alsaconf = new FsoFramework.SmartKeyFile();
        if ( alsaconf.loadFromFile( FSO_ALSA_CONF_PATH ) )
        {
            device = FsoFramework.SoundDevice.create( alsaconf.stringValue( "alsa", "cardname", "default" ) );
            var defaultscenario = alsaconf.stringValue( "alsa", "default_scenario", "stereoout" );

            var sections = alsaconf.sectionsWithPrefix( "scenario." );
            foreach ( var section in sections )
            {
                var scenario = section.split( "." )[1];
                if ( scenario != "" )
                {
                    logger.debug( "Found scenario '%s'".printf( scenario ) );

                    var file = File.new_for_path( Path.build_filename( FSO_ALSA_DATA_PATH, scenario ) );
                    if ( !file.query_exists(null) )
                    {
                        logger.warning( "Scenario file %s doesn't exist. Ignoring.".printf( file.get_path() ) );
                    }
                    else
                    {
                        addScenario( scenario, file );
                    }
                }
            }

            if ( defaultscenario in allscenarios )
            {
                push_scenario( defaultscenario ); // ASYNC
            }
            else
            {
                logger.warning( "Default scenario not found; can't push it to scenario stack" );
            }
            // listen for changes
            FsoFramework.INotifier.add( FSO_ALSA_DATA_PATH, Linux.InotifyMaskFlags.MODIFY, onModifiedScenario );
        }
        else
        {
            logger.warning( "Could not load %s. No scenarios available.".printf( FSO_ALSA_CONF_PATH ) );
        }
    }

    private void updateScenarioIfChanged( string scenario )
    {
        if ( currentscenario != scenario )
        {
            assert ( device != null );
            device.setAllMixerControls( allscenarios[scenario].controls );

            currentscenario = scenario;
            this.scenario( currentscenario, "N/A" ); // DBUS SIGNAL
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

        if ( name == currentscenario )
        {
            logger.info( @"Scenario $name has been changed (being also the current scenario); invalidating cache and reloading" );
            var file = File.new_for_path( Path.build_filename( FSO_ALSA_DATA_PATH, name ) );
            if ( !file.query_exists(null) )
            {
                logger.warning( @"Scenario file $(file.get_path()) doesn't exist. Ignoring." );
            }
            else
            {
                addScenario( name, file );
                device.setAllMixerControls( allscenarios[name].controls );
            }
        }
        else
        {
            logger.info( @"Scenario $name has been changed; invalidating cache for this." );
            // save current one
            var scene = new FsoFramework.BunchOfMixerControls( device.allMixerControls() );
            // reload changed one from disk
            var file = File.new_for_path( Path.build_filename( FSO_ALSA_DATA_PATH, name ) );
            if ( !file.query_exists(null) )
            {
                logger.warning( @"Scenario file $(file.get_path()) doesn't exist. Ignoring." );
            }
            else
            {
                addScenario( name, file );
            }
            // restore saved one
            device.setAllMixerControls( scene.controls );
        }
    }

    //
    // FreeSmartphone.Device.Sound (DBUS API)
    //

    //
    // Scenario
    public async string[] get_available_scenarios() throws DBus.Error
    {
        string[] list = {};
        foreach ( var key in allscenarios.keys )
            list += key;
        return list;
    }

    public async HashTable<string,Value?> get_info() throws DBus.Error
    {
        var dict = new HashTable<string,Value?>( str_hash, str_equal );

        /*
        var value = Value( typeof(string[] ) );
        string[] formats = { "wav" };
        value.take_
        value = formats;

        /*
        dict.insert( "formats", value );
        Value scenario = get_scenario();
        dict.insert( "scenario", value );
        Value scenarios = get_available_scenarios();
        dict.insert( "scenarios", value );
        */
        return   dict;
    }

    public async string get_scenario() throws DBus.Error
    {
        return currentscenario;
    }

    public async string pull_scenario() throws FreeSmartphone.Device.AudioError, DBus.Error
    {
        scenarios.pop_head();
        var scenario = scenarios.peek_head();
        if ( scenario == null )
        {
            throw new FreeSmartphone.Device.AudioError.SCENARIO_STACK_UNDERFLOW( "No scenario left to activate" );
        }
        yield set_scenario( scenario );
        return scenario;
    }

    public async void push_scenario( string scenario ) throws FreeSmartphone.Error, DBus.Error
    {
        // try to set this scenario, will error out if not successful
        yield set_scenario( scenario );
        // push on the stack
        scenarios.push_head( scenario );
    }

    public async void set_scenario( string scenario ) throws FreeSmartphone.Error, DBus.Error
    {
        if ( !( scenario in allscenarios.keys ) )
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Could not find scenario %s".printf( scenario ) );

        updateScenarioIfChanged( scenario );
    }

    public async void save_scenario( string scenario ) throws FreeSmartphone.Error, DBus.Error
    {
        if ( !( scenario in allscenarios.keys ) )
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Could not find scenario %s".printf( scenario ) );

        var scene = new FsoFramework.BunchOfMixerControls( device.allMixerControls() );

        var filename = Path.build_filename( FSO_ALSA_DATA_PATH, scenario );
        FsoFramework.FileHandling.write( scene.to_string(), filename );
    }

    //
    // Sound
    public async void play_sound( string name, int loop, int length ) throws FreeSmartphone.Device.AudioError, FreeSmartphone.Error, DBus.Error
    {
        yield player.play_sound( name, loop, length );
    }

    public async void stop_all_sounds() throws DBus.Error
    {
        yield player.stop_all_sounds();
    }

    public async void stop_sound( string name ) throws FreeSmartphone.Error, DBus.Error
    {
        yield player.stop_sound( name );
    }
}

} /* namespace */

internal Alsa.AudioPlayer instance;

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    instance = new Alsa.AudioPlayer( subsystem );

    return "fsodevice.alsa_audio";
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    debug( "input fso_register_function()" );
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
