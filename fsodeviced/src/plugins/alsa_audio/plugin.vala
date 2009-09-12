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

using GLib;
using Gee;

const string FSO_ALSA_CONF_PATH = "/etc/freesmartphone/alsa/default.conf";
const string FSO_ALSA_DATA_PATH = "/etc/freesmartphone/alsa/default/";

namespace Alsa
{

/**
 * Helper class, encapsulating a sound that's currently playing
 **/
public class PlayingSound
{
    public string name;
    public int loop;
    public int length;
    public bool finished;

    public uint watch;

    public PlayingSound( string name, int loop, int length )
    {
        this.name = name;
        this.loop = loop;
        this.length = length;

        if ( length > 0 )
            watch = Timeout.add_seconds( length, onTimeout );
    }

    public bool onTimeout()
    {
        instance.stop_sound( name );
        return false;
    }

    ~PlayingSound()
    {
        if ( watch > 0 )
            Source.remove( watch );
    }
}

/**
 * Scenario
 **/
class BunchOfMixerControls
{
    public FsoFramework.MixerControl[] controls;
}

/**
 * Alsa Audio Player
 **/
class AudioPlayer : FreeSmartphone.Device.Audio, FsoFramework.AbstractObject
{
    private FsoFramework.Subsystem subsystem;

    private Canberra.Context context;
    private HashMap<string,PlayingSound> sounds;
    private FsoFramework.Async.EventFd eventfd;

    private FsoFramework.SoundDevice device;
    private HashMap<string,BunchOfMixerControls> allscenarios;
    private string currentscenario;
    private GLib.Queue<string> scenarios;

    //private Mutex mutex;

    public AudioPlayer( FsoFramework.Subsystem subsystem )
    {
        this.subsystem = subsystem;

        subsystem.registerServiceName( FsoFramework.Device.ServiceDBusName );
        subsystem.registerServiceObject( FsoFramework.Device.ServiceDBusName,
                                         FsoFramework.Device.AudioServicePath,
                                         this );

        // init sounds
        sounds = new HashMap<string,PlayingSound>( str_hash, str_equal );
        Canberra.Context.create( &context );
        eventfd = new FsoFramework.Async.EventFd( 0, onAsyncEvent );

        initScenarios();
        if ( currentscenario != "" )
            device.setAllMixerControls( allscenarios[currentscenario].controls );

        //mutex = new Mutex();

        logger.info( "created." );
    }

    public override string repr()
    {
        return "<ALSA>";
    }

    /* CAUTION: Note the following quote from the libcanberra API documentation:
     * "The context this callback is called in is undefined, it might or might not be
     * called from a background thread, and from any stack frame. The code implementing
     * this function may not call any libcanberra API call from this callback -- this
     * might result in a deadlock. Instead it may only be used to asynchronously signal
     * some kind of notification object (semaphore, message queue, ...).
     */
    public void onPlayingSoundFinished( Canberra.Context context, uint32 id, Canberra.Error code )
    {
        message( "number of keys in hashmap = %d", sounds.size );
        //mutex.lock();

        message( "onPlayingSoundFinished w/ id: %0x", id );
        var name = ( (Quark) id ).to_string();
        logger.debug( "Sound finished with name %s (%0x), code %s".printf( name, id, Canberra.strerror( code ) ) );
        PlayingSound sound = sounds[name];
        assert ( sound != null );

        sound.finished = true;

        if ( code == Canberra.Error.CANCELED || sound.loop == 0 )
        {
            message( "removing sound w/ id %0x", id );
            sounds.remove( name );
            //FIXME send signal
        }
        else
        {
            // wake up mainloop to repeat
            eventfd.write( (int)id );
        }

        //mutex.unlock();
    }

    public bool onAsyncEvent( IOChannel channel, IOCondition condition )
    {
        uint id = eventfd.read();
        var name = ( (Quark) id ).to_string();
        PlayingSound sound = sounds[name];
        if ( sound.finished && sound.loop-- > 0 )
        {
            sound.finished = false;

            Canberra.Proplist p = null;
            Canberra.Proplist.create( &p );
            p.sets( Canberra.PROP_MEDIA_FILENAME, sound.name );

            Canberra.Error res = context.play_full( Quark.from_string( sound.name ), p, onPlayingSoundFinished );
        }
        else
        {
            message( "removing sound w/ id %0x", id );
            sounds.remove( name );
            //FIXME send stopped signal
        }
        return true; // MainLoop: call me again
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
            var bunch = new BunchOfMixerControls();
            bunch.controls = controls;
            allscenarios[scenario] = bunch;
        }
        catch (IOError e)
        {
            logger.error( "%s".printf( e.message ) );
        }
    }

    private void initScenarios()
    {
        allscenarios = new HashMap<string,BunchOfMixerControls>( str_hash, str_equal );
        currentscenario = "";

        // init scenarios
        FsoFramework.SmartKeyFile alsaconf = new FsoFramework.SmartKeyFile();
        if ( alsaconf.loadFromFile( FSO_ALSA_CONF_PATH ) )
        {
            device = FsoFramework.SoundDevice.create( alsaconf.stringValue( "alsa", "cardname", "default" ) );
            currentscenario = alsaconf.stringValue( "alsa", "default_scenario", "stereoout" );

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
        }
        else
        {
            logger.warning( "Could not load %s. No scenarios available.".printf( FSO_ALSA_CONF_PATH ) );
        }
    }

    //
    // DBUS API
    //

    //
    // Scenario
    public string[] get_available_scenarios() throws DBus.Error
    {
        string[] list = {};
        foreach ( var key in allscenarios.get_keys() )
            list += key;
        return list;
    }

    public HashTable<string,Value?> get_info() throws DBus.Error
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
        return dict;
    }

    public string get_scenario() throws DBus.Error
    {
        return currentscenario;
    }

    public string pull_scenario() throws FreeSmartphone.Device.AudioError, DBus.Error
    {
        var scenario = scenarios.pop_head();
        if ( scenario == null )
            throw new FreeSmartphone.Device.AudioError.SCENARIO_STACK_UNDERFLOW( "No scenario to pull" );
        set_scenario( scenario );
        return scenario;
    }

    public void push_scenario( string scenario ) throws DBus.Error
    {
        scenarios.push_head( scenario );
        set_scenario( scenario );
    }

    public void set_scenario( string scenario ) throws /* FreeSmartphone.Error, */ DBus.Error
    {
        if ( !( scenario in allscenarios.get_keys() ) )
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Could not find scenario %s".printf( scenario ) );

        assert ( device != null );

        device.setAllMixerControls( allscenarios[scenario].controls );
    }

    //
    // Sound
    public void play_sound( string name, int loop, int length ) throws FreeSmartphone.Device.AudioError, DBus.Error
    {
        PlayingSound sound = sounds[name];
        if ( sound != null )
            throw new FreeSmartphone.Device.AudioError.ALREADY_PLAYING( "%s is already playing".printf( name ) );

        Canberra.Proplist p = null;
        Canberra.Proplist.create( &p );
        p.sets( Canberra.PROP_MEDIA_FILENAME, name );

        //message( "canberra context.play_full %s (%0x)", name, Quark.from_string( name ) );
        Canberra.Error res = context.play_full( Quark.from_string( name ), p, onPlayingSoundFinished );

        if ( res != Canberra.SUCCESS )
        {
            throw new FreeSmartphone.Device.AudioError.PLAYER_ERROR( "Can't play song %s: %s".printf( name, Canberra.strerror( res ) ) );
        }

        sounds[name] = new PlayingSound( name, loop, length );
    }

    public void stop_all_sounds() throws DBus.Error
    {
        foreach ( var name in sounds.get_keys() )
        {
            //message( "stopping sound '%s' (%0x)", name, Quark.from_string( name ) );
            stop_sound( name );
        }
    }

    public void stop_sound( string name ) throws DBus.Error
    {
        PlayingSound sound = sounds[name];
        if ( sound == null )
            return;

        Canberra.Error res = context.cancel( Quark.from_string( name ) );
        logger.debug( "cancelling %s (%0x) result: %s".printf( sound.name, Quark.from_string( name ), Canberra.strerror( res ) ) );
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
