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

namespace Alsa
{

/**
 * Helper class, encapsulating a sound that's currently playing
 **/
[Compact]
public class PlayingSound
{
    public string name;
    public int loop;
    public int length;
    public int cid;
    public bool finished;

    public uint watch;

    public PlayingSound( string name, int loop, int length, int cid )
    {
        this.name = name;
        this.loop = loop;
        this.length = length;
        this.cid = cid;

        if ( length > 0 )
            watch = Timeout.add_seconds( length, onTimeout );
        //message( "%s %d create", name, cid );
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
        //message( "%s %d destroy", name, cid );
    }
}

/**
 * Alsa Audio Player
 **/
class AudioPlayer : FreeSmartphone.Device.Audio, FsoFramework.AbstractObject
{
    private FsoFramework.Subsystem subsystem;
    private Sound.Scenario scenario;
    private Canberra.Context context;
    private HashTable<string,PlayingSound> sounds;
    private Queue<string> scenarios;

    private FsoFramework.Async.EventFd eventfd;

    public AudioPlayer( FsoFramework.Subsystem subsystem )
    {
        this.subsystem = subsystem;

        subsystem.registerServiceName( FsoFramework.Device.ServiceDBusName );
        subsystem.registerServiceObject( FsoFramework.Device.ServiceDBusName,
                                         FsoFramework.Device.AudioServicePath,
                                         this );

        sounds = new HashTable<string,PlayingSound>( str_hash, str_equal );

        Canberra.Context.create( &context );
        scenario = new Sound.Scenario();

        eventfd = new FsoFramework.Async.EventFd( 0, onAsyncEvent );

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
        logger.debug( "sound finished with name %s, code %s".printf( (string)id, Canberra.strerror( code ) ) );
        weak PlayingSound sound = sounds.lookup( (string)id );
        assert ( sound != null );
        sound.finished = true;

        if ( code == Canberra.Error.CANCELED || sound.loop == 0 )
        {
            sounds.remove( (string)id );
            //FIXME send signal
        }
        else
        {
            // wake up mainloop to repeat
            eventfd.write( (int)id );
        }
    }

    public bool onAsyncEvent( IOChannel channel, IOCondition condition )
    {
        //message( "async trigger" );
        uint value = eventfd.read();
        //message( "on async event: %u", value );
        foreach ( var name in sounds.get_keys() )
        {
            weak PlayingSound sound = sounds.lookup( name );
            if ( sound.finished && sound.loop-- > 0 )
            {
                sound.finished = false;

                Canberra.Proplist p = null;
                Canberra.Proplist.create( &p );
                p.sets( Canberra.PROP_MEDIA_FILENAME, sound.name );

                Canberra.Error res = context.play_full( sound.cid, p, onPlayingSoundFinished );
            }
            else
            {
                sounds.remove( name );
            //FIXME send stopped signal
            }
        }
        return true; // MainLoop: call me again
    }

    //
    // DBUS API
    //
    public string[] get_available_scenarios() throws DBus.Error
    {
        string[] list;
        scenario.list( out list );
        return list;
    }

    public HashTable<string,Value?> get_info() throws DBus.Error
    {
        return new HashTable<string,Value?>( str_hash, str_equal );
    }

    public string get_scenario() throws DBus.Error
    {
        return scenario.get_scn();
    }

    public string[] get_supported_formats() throws DBus.Error
    {
        return { "*.wav" };
    }

    public void play_sound( string name, int loop, int length ) throws FreeSmartphone.Device.AudioError, DBus.Error
    {
        weak PlayingSound sound = sounds.lookup( name );
        if ( sound != null )
            throw new FreeSmartphone.Device.AudioError.ALREADY_PLAYING( "%s is already playing".printf( name ) );

        Canberra.Proplist p = null;
        Canberra.Proplist.create( &p );
        p.sets( Canberra.PROP_MEDIA_FILENAME, name );

        Canberra.Error res = context.play_full( (uint32)name, p, onPlayingSoundFinished );

        if ( res != Canberra.SUCCESS )
        {
            throw new FreeSmartphone.Device.AudioError.PLAYER_ERROR( "Can't play song %s: %s".printf( name, Canberra.strerror( res ) ) );
        }

        sounds.insert( name, new PlayingSound( name, loop, length, (int)name ) );
    }

    public string pull_scenario() throws DBus.Error
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

    public void set_scenario( string scenario ) throws DBus.Error
    {
        var res = this.scenario.set_scn( scenario );
        if ( res < 0 )
            throw new FreeSmartphone.Device.AudioError.SCENARIO_INVALID( "Could not find %s".printf( scenario ) );
    }

    public void stop_all_sounds() throws DBus.Error
    {
        foreach ( var name in sounds.get_keys() )
            stop_sound( name );
    }

    public void stop_sound( string name ) throws DBus.Error
    {
        weak PlayingSound sound = sounds.lookup( name );
        if ( sound == null )
            return;

        Canberra.Error res = context.cancel( sound.cid );
        logger.debug( "cancelling %s (%d) result: %s".printf( sound.name, sound.cid, Canberra.strerror( res ) ) );
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