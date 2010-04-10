/**
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
 **/

//=========================================================================//
using GLib;

//=========================================================================//
class Commands : Object
{
    DBus.Connection bus;
    dynamic DBus.Object usage;

    public Commands()
    {
    }
}

//=========================================================================//
static bool listresources;
static bool force;
static bool timeout;
[NoArrayLength()]
static string[] resources;
[NoArrayLength()]
static string[] command;

const OptionEntry[] options =
{
    { "listresources", 'l', 0, OptionArg.NONE, ref listresources, "List resources (do not mix with -r)", null },
    { "resources", 'r', 0, OptionArg.STRING_ARRAY, ref resources, "Allocate resources during program execution", "RESOURCE..." },
    { "force", 'f', 0, OptionArg.NONE, ref force, "Continue execution, even if (some) resources can't be allocated.", null },
    { "timeout", 't', 0, OptionArg.INT, ref timeout, "Override default dbus timeout", "MSECS" },
    { "", 0, 0, OptionArg.FILENAME_ARRAY, ref command, null, "[--] COMMAND [ARGS]..." },
    { null }
};

//=========================================================================//
int main( string[] args )
{
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
    return 0;
}

