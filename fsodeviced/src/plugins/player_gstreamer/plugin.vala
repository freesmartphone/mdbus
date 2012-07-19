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

using GLib;
using Gee;
using FsoDevice;

/**
 * AudioPlayer using gstreamer
 **/
class Player.Gstreamer : FsoDevice.BaseAudioPlayer
{
    private const int FORCED_STOP = 42;

    private Gee.HashMap<string,string> decoders;
    private Gee.HashMap<string,Gst.Pipeline> pipelines;

    construct
    {
        // check which decoders we support
        decoders = new Gee.HashMap<string,string>();
        trySetupDecoder( "mod", "modplug" );
        trySetupDecoder( "mp3", "mad" );
        trySetupDecoder( "sid", "siddec" );
        trySetupDecoder( "wav", "wavparse" );
        // ogg fixed point decoder, found on embedded systems
        bool haveIt = trySetupDecoder( "ogg", "oggdemux ! ivorbisdec ! audioconvert" );
        if ( !haveIt )
        {
            // ogg w/ floating point vorbis decoder, found on desktop systems
            trySetupDecoder( "ogg", "oggdemux ! vorbisdec ! audioconvert" );
        }

        pipelines = new Gee.HashMap<string,Gst.Pipeline>();
    }

    private bool trySetupDecoder( string extension, string decoder )
    {
        // FIXME might even save the elements already, not just the description
        try
        {
            Gst.parse_bin_from_description( decoder, false );
            decoders[extension] = decoder;
            return true;
        }
        catch ( GLib.Error e )
        {
            FsoFramework.theLogger.warning( @"Gstreamer does not understand $decoder; not adding to map" );
            return false;
        }
    }

    private bool onGstreamerMessage( Gst.Bus bus, Gst.Message message, PlayingSound sound )
    {
        assert( FsoFramework.theLogger.debug( @"Gstreamer: $(message.type) for sound $(sound.name)" ) );

        var pipeline = sound.data as Gst.Pipeline;

        switch ( message.type )
        {
            case Gst.MessageType.EOS:
            {
                if ( sound.loop-- > 0 )
                {
                    pipeline.seek_simple( Gst.Format.TIME, Gst.SeekFlags.FLUSH, 0 );
                }
                else
                {
                    stop( sound );
                }
                break;
            }
            case Gst.MessageType.ERROR:
            {
                GLib.Error e;
                string debug;
                message.parse_error( out e, out debug );
                FsoFramework.theLogger.warning( @"Gstreamer: Error $(e.message): $debug" );
                break;
            }
            case Gst.MessageType.STATE_CHANGED:
            {
                Gst.State previous;
                Gst.State current;
                Gst.State pending;

                message.parse_state_changed( out previous, out current, out pending );

                //logger.debug( "G: STATE NOW: (%s) -> %s -> (%s)" % ( previous, current, pending ) )

                if ( previous == Gst.State.READY && current == Gst.State.PAUSED && pending == Gst.State.PLAYING )
                {
                    if ( sound.length > 0 )
                    {
                        Timeout.add_seconds( sound.length, () => {
                            stop( sound );
                            return false;
                        } );
                    }
                    // TODO: send signal
                }
                else if ( previous == Gst.State.PLAYING && current == Gst.State.PAUSED && pending == Gst.State.READY )
                {
                    stop( sound );
                }
                else
                {
                    // uninteresting state change
                }
                break;
            }
            default:
            {
                FsoFramework.theLogger.warning( @"Gstreamer: Unhandled message w/ type $(message.type)" );
                break;
            }
        }
        return true;
    }

    private void stop( PlayingSound sound )
    {
        //TODO: send signal
        var pipeline = sound.data as Gst.Pipeline;
        pipeline.set_state( Gst.State.NULL );
        sounds.remove( sound.name );
        pipelines.remove( sound.name );
    }

    //
    // AudioPlayer API
    //
    public override string[] supportedFormats()
    {
        // work around Gee.Collection.to_array() not populating the length attribute of an array
        string[] keys = {};
        foreach ( var key in decoders.keys )
        {
            keys += key;
        }
        return keys;
    }

    public override async void play_sound( string name, int loop, int length ) throws FreeSmartphone.Device.AudioError, FreeSmartphone.Error
    {
        PlayingSound sound = sounds[name];
        if ( sound != null )
        {
            throw new FreeSmartphone.Device.AudioError.ALREADY_PLAYING( "%s is already playing".printf( name ) );
        }

        var parts = name.split( "." );
        if ( parts.length == 0 )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Could not guess media format; need an extension" );
        }
        var extension = parts[ parts.length - 1 ]; // darn, I miss negative array indices
        var decoder = decoders[extension];
        assert( decoder != null );

        assert( this != null );

        try
        {
            var pipeline = Gst.parse_launch( @"filesrc location=\"$name\" ! $decoder ! alsasink" ) as Gst.Pipeline;
            sound = new PlayingSound( name, loop, length, (uint32)pipeline );

            Gst.Bus bus = pipeline.get_bus();
            bus.add_watch_full( 0, ( bus, message ) => {
                assert( this != null );
                return onGstreamerMessage( bus, message, sound );
            } );
            pipeline.set_state( Gst.State.PLAYING );
            pipelines[name] = pipeline;
            sounds[name] = sound;
        }
        catch ( GLib.Error e )
        {
            FsoFramework.theLogger.warning( @"Could not create/launch GStreamer pipeline: $(e.message)" );
            return;
        }
    }

    public override async void stop_all_sounds()
    {
        foreach ( var sound in sounds.values )
        {
            Idle.add( () => {
                stop( sound );
                return false;
            } );
        }
    }

    public override async void stop_sound( string name ) throws FreeSmartphone.Error
    {
        PlayingSound sound = sounds[name];
        if ( sound == null )
        {
            return;
        }
        stop( sound );
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
    unowned string[] args = null;
    // instances will be created on demand by alsa_audio
    GLib.g_thread_init(); // from thread.vapi
    Gst.init( ref args );
    return "fsodevice.player_gstreamer";
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsodevice.player_gstreamer fso_register_function()" );
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
