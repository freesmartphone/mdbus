/*
 * FSO Alsa Testing / Diagnostics Utility
 *
 * Copyright (C) 2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
    }
}

//=========================================================================//
static string cardname;
static bool dump;
static bool info;
[NoArrayLength()]
static string[] command;

const OptionEntry[] options =
{
    { "cardname", 'c', 0, OptionArg.STRING, ref cardname, "The card name [default='default']", "CARDNAME" },
    { "", 0, 0, OptionArg.FILENAME_ARRAY, ref command, null, "[--] COMMAND [ARGS]..." },
    { null }
};

//=========================================================================//
int main( string[] args )
{
    cardname = "default";

    try
    {
        var opt_context = new OptionContext( "- FSO Alsa Diagnostics" );
        opt_context.set_help_enabled( true );
        opt_context.add_main_entries( options, null );
        opt_context.parse( ref args );
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
        default:
            commands.info();
            break;
    }

    return 0;
}

