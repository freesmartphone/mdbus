/**
 * -- Mickey's DBus Utility V2 --
 *
 * Copyright (C) 2009 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
const string FSO_USAGE_BUS   = "org.freesmartphone.ousaged";
const string FSO_USAGE_PATH  = "/org/freesmartphone/Usage";
const string FSO_USAGE_IFACE = "org.freesmartphone.Usage";

//=========================================================================//
MainLoop mainloop;

//=========================================================================//
class Commands : Object
{
    DBus.Connection bus;
    dynamic DBus.Object busobj;

    public Commands()
    {
        try
        {
            bus = DBus.Bus.get( DBus.BusType.SYSTEM );
        }
        catch ( DBus.Error e )
        {
            critical( "dbus error: %s", e.message );
        }
    }

    public void suspend()
    {
        busobj = bus.get_object( FSO_USAGE_BUS, FSO_USAGE_PATH, FSO_USAGE_IFACE );
        try
        {
            busobj.Suspend();
        }
        catch ( DBus.Error e )
        {
            stderr.printf( "%s\n", e.message );
        }
    }

    public void showPowerStatus()
    {
        // FIXME...
        stdout.printf( "Sorry, NYI...\n" );
    }
}

//=========================================================================//
bool suspend;

const OptionEntry[] options =
{
    { "suspend", 's', 0, OptionArg.NONE, ref suspend, "Suspend the device", null },
    { null }
};

//=========================================================================//
int main( string[] args )
{
    try
    {
        var opt_context = new OptionContext( "- FSO APM Compatibility Utility V2" );
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
    if ( suspend)
        commands.suspend();
    else
        commands.showPowerStatus();

    return 0;
}

