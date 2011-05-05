/**
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
using FsoDevice;

/**
 * AudioPlayer using libcanberra
 **/
class Player.LibCanberra : FsoDevice.BaseAudioPlayer
{
    private Canberra.Context context;
    private FsoFramework.Async.EventFd eventfd;

    construct /* this class will be created via Object.new */
    {
        Canberra.Context.create( out context );
        eventfd = new FsoFramework.Async.EventFd( 0, onAsyncEvent );
    }

    /* CAUTION: Note the following quote from the libcanberra API documentation:
     * "The context this callback is called in is undefined, it might or might not be
     * called from a background thread, and from any stack frame. The code implementing
     * this function may not call any libcanberra API call from this callback -- this
     * might result in a deadlock. Instead it may only be used to asynchronously signal
     * some kind of notification object (semaphore, message queue, ...).
     */
    public void onPlayingSoundFinished( Canberra.Context context, uint32 id, int code )
    {
        message( "number of keys in hashmap = %d", sounds.size );

        message( "onPlayingSoundFinished w/ id: %0x", id );
        var name = ( (Quark) id ).to_string();
        debug( "Sound finished with name %s (%0x), code %s".printf( name, id, Canberra.strerror( code ) ) );
        PlayingSound sound = sounds[name];
        assert ( sound != null );

        sound.finished = true;

        if ( (Canberra.Error)code == Canberra.Error.CANCELED || sound.loop == 0 )
        {
            message( "removing sound w/ id %0x", id );
            sounds.remove( name );
        }
        else
        {
            // wake up mainloop to repeat
            eventfd.write( (int)id );
        }
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
            Canberra.Proplist.create( out p );
            p.sets( Canberra.PROP_MEDIA_FILENAME, sound.name );

            Canberra.Error res = (Canberra.Error) context.play_full( Quark.from_string( sound.name ), p, onPlayingSoundFinished );
        }
        else
        {
            message( "removing sound w/ id %0x", id );
            sounds.remove( name );
        }
        return true; // MainLoop: call me again
    }

    //
    // AudioPlayer API
    //
    public override string[] supportedFormats()
    {
        return { "wav", "ogg" };
    }

    public override async void play_sound( string name, int loop, int length ) throws FreeSmartphone.Device.AudioError, FreeSmartphone.Error
    {
        PlayingSound sound = sounds[name];
        if ( sound != null )
            throw new FreeSmartphone.Device.AudioError.ALREADY_PLAYING( "%s is already playing".printf( name ) );

        Canberra.Proplist p = null;
        Canberra.Proplist.create( out p );
        p.sets( Canberra.PROP_MEDIA_FILENAME, name );

        //message( "canberra context.play_full %s (%0x)", name, Quark.from_string( name ) );
        Canberra.Error res = (Canberra.Error) context.play_full( Quark.from_string( name ), p, onPlayingSoundFinished );

        if ( res != Canberra.SUCCESS )
        {
            throw new FreeSmartphone.Device.AudioError.PLAYER_ERROR( "Can't play song %s: %s".printf( name, Canberra.strerror( res ) ) );
        }

        sounds[name] = new PlayingSound( name, loop, length );
        sounds[name].soundFinished.connect( (name) => { stop_sound( name ); } );
    }

    public override async void stop_all_sounds()
    {
        foreach ( var name in sounds.keys )
        {
            //message( "stopping sound '%s' (%0x)", name, Quark.from_string( name ) );
            yield stop_sound( name );
        }
    }

    public override async void stop_sound( string name ) throws FreeSmartphone.Error
    {
        PlayingSound sound = sounds[name];
        if ( sound == null )
            return;

        Canberra.Error res = (Canberra.Error) context.cancel( Quark.from_string( name ) );
        debug( "cancelling %s (%0x) result: %s".printf( sound.name, Quark.from_string( name ), Canberra.strerror( res ) ) );
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
    // instances will be created on demand by alsa_audio
    return "fsodevice.player_canberra";
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsodevice.player_canberra fso_register_function()" );
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
