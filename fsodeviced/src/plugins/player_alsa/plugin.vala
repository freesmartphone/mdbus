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
using FsoDevice;

/**
 * AudioPlayer using libalsa
 **/
class Player.LibAlsa : FsoDevice.BaseAudioPlayer
{
    public void onChildWatchEvent( Pid pid, int status )
    {
        debug( "CHILD WATCH EVENT FOR %d: %d", (int)pid, status );
        Process.close_pid( pid );

        foreach ( var name in sounds.keys )
        {
            if ( sounds[name].data == (uint32)pid )
            {
                sounds.remove( name );
                return;
            }
        }
    }

    //
    // AudioPlayer API
    //
    public override async void play_sound( string name, int loop, int length ) throws FreeSmartphone.Device.AudioError, FreeSmartphone.Error
    {
        PlayingSound sound = sounds[name];
        if ( sound != null )
            throw new FreeSmartphone.Device.AudioError.ALREADY_PLAYING( "%s is already playing".printf( name ) );

        var params = new string[] { "aplay", name, null };
        Pid pid;
        var res = 0;
        try
        {
            GLib.Process.spawn_async( GLib.Environment.get_variable( "PWD" ),
                                      params,
                                      null,
                                      GLib.SpawnFlags.DO_NOT_REAP_CHILD | GLib.SpawnFlags.SEARCH_PATH,
                                      null,
                                      out pid );
        }
        catch ( SpawnError e )
        {
            warning( @"Can't spawn aplay: $(strerror(errno))" );
            throw new FreeSmartphone.Device.AudioError.PLAYER_ERROR( "Can't play song %s: %s".printf( name, Alsa.strerror( res ) ) );
        }

        GLib.ChildWatch.add( pid, onChildWatchEvent );

        sounds[name] = new PlayingSound( name, loop, length, (uint32)pid );
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
        /*
        PlayingSound sound = sounds[name];
        if ( sound == null )
            return;

        Alsa.Error res = (Alsa.Error) context.cancel( Quark.from_string( name ) );
        debug( "cancelling %s (%0x) result: %s".printf( sound.name, Quark.from_string( name ), Alsa.strerror( res ) ) );
        */
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
    return "fsodevice.player_alsa";
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
