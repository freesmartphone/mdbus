/*
 * FSO Alsa Testing / Diagnostics Utility
 *
 * Copyright (C) 2010-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

//=========================================================================//
using GLib;
using FsoDevice;
using Alsa2;

//=========================================================================//
class Commands : Object
{
    public Commands()
    {
    }

    public void dumpScenario()
    {
        var sd = SoundDevice.create( cardname );
        var controls = sd.allMixerControls();
        stdout.printf( @"# scenario for cardname $cardname (%d controls)\n", controls.length );
        foreach ( var control in controls )
        {
            stdout.printf( @"$control\n" );
        }
    }

    public void dumpMixer()
    {
        Alsa.Mixer mix;
        Alsa.Mixer.open( out mix );
        assert( mix != null );
        mix.attach( cardname );
        mix.register();
        mix.load();

        Alsa.SimpleElementId seid;
        Alsa.SimpleElementId.alloc( out seid );

        stdout.printf( @"# simple mixer settings\n" );

        for ( Alsa.MixerElement mel = mix.first_elem(); mel != null; mel = mel.next() )
        {
            long val;
            long min;
            long max;
            mel.get_playback_volume( Alsa.SimpleChannelId.MONO, out val );
            mel.get_playback_volume_range( out min, out max );

            mel.get_id( seid );
            var name = seid.get_name();

            stdout.printf( @"$name: [ $min - $val - $max ]\n" );
        }
    }

    public void info()
    {
        stdout.printf( """Unknown command; available commands are:

scenario:             Dump the current alsa scenario in fso-format,
mixer:                Dump the current alsa simple mixer settings,
record:               Record into file 'audio.raw'
play:                 Play from file 'audio.raw'
""" );
    }

    public void record()
    {
    }

    public void play()
    {
        PcmDevice pcm;
        var ok = PcmDevice.open( out pcm, cardname, PcmStream.PLAYBACK );
        message( @"ok = $ok" );
        assert( pcm != null );

        PcmHardwareParams hwparams;
        PcmHardwareParams.malloc( out hwparams );
        message( @"ok = $ok" );

        ok = pcm.hw_params_any( hwparams );
        message( @"ok = $ok" );
        ok = pcm.hw_params_set_access( hwparams, PcmAccess.RW_INTERLEAVED );
        message( @"ok = $ok" );
        ok = pcm.hw_params_set_format( hwparams, PcmFormat.S8 );
        message( @"ok = $ok" );
        int rate = 8000;
        ok = pcm.hw_params_set_rate_near( hwparams, ref rate, 0 );
        message( @"ok = $ok" );
        ok = pcm.hw_params_set_channels( hwparams, 1 );
        message( @"ok = $ok" );
        ok = pcm.hw_params( hwparams );
        message( @"ok = $ok" );
        ok = pcm.prepare();
        message( @"ok = $ok" );

        var fd = Posix.open( "audio.raw", Posix.O_RDONLY );
        if ( fd != -1 )
        {
            uint8[] buffer = new uint8[2048];
            ssize_t bread = 0;
            while ( ( bread = Posix.read( fd, buffer, 2048 ) ) > 0 )
            {
                message( @"read $bread bytes from fd" );
                PcmUnsignedFrames written = pcm.writei( (void*) buffer, (PcmUnsignedFrames) (int) ( bread / 1 ) );
                message( "wrote %d frames", (int)written );
            }
        }

        while ( pcm.drain() > 0 );
    }
}

//=========================================================================//
static string cardname;
static bool dump;
static bool info;
[NoArrayLength()]
static string[] command;

const OptionEntry[] opts =
{
    { "cardname", 'c', 0, OptionArg.STRING, ref cardname, "The card name [default='default']", "CARDNAME" },
    { "", 0, 0, OptionArg.FILENAME_ARRAY, ref command, null, "[--] COMMAND [ARGS]..." },
    { null }
};

//=========================================================================//
int main( string[] args )
{
    cardname = "default";

    OptionContext options;

    try
    {
        options = new OptionContext( "- FSO Alsa Diagnostics" );
        options.set_help_enabled( true );
        options.add_main_entries( opts, null );
        options.parse( ref args );
    }
    catch ( OptionError e )
    {
        stdout.printf( "%s\n", e.message );
        stdout.printf( "Run '%s --help' to see a full list of available command line options.\n", args[0] );
        return 1;
    }

    var commands = new Commands();
    if ( command == null )
    {
        commands.info();
        return 0;
    }
    switch ( command[0] )
    {
        case "scenario":
            commands.dumpScenario();
            break;
        case "mixer":
            commands.dumpMixer();
            break;
        case "play":
            commands.play();
            break;
        default:
            commands.info();
            break;
    }

    return 0;
}

// vim:ts=4:sw=4:expandtab
