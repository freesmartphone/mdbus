/*
 * -- FSO APM Compatibility Utility --
 *
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

const string FSO_DEVICE_BUS  = "org.freesmartphone.odeviced";
const string FSO_DEVICE_PATH = "/org/freesmartphone/Device/PowerSupply";

//=========================================================================//
MainLoop mainloop;

//=========================================================================//

[DBus (timeout = 120000, name = "org.freesmartphone.Usage")]
public interface IUsage : GLib.Object
{
    public abstract void suspend () throws GLib.DBusError, GLib.IOError, GLib.Error;
}

[DBus (timeout = 120000, name = "org.freesmartphone.Device.PowerSupply")]
public interface IPowerSupply : GLib.Object
{
    public abstract int get_capacity () throws GLib.DBusError, GLib.IOError;
    public abstract string get_power_status () throws GLib.DBusError, GLib.IOError;
}

//=========================================================================//
class Commands : Object
{
    public void suspend()
    {
        try
        {
            IUsage usage = Bus.get_proxy_sync<IUsage>( BusType.SYSTEM, FSO_USAGE_BUS, FSO_USAGE_PATH );
            usage.suspend();
        }
        catch ( GLib.Error e )
        {
            stderr.printf( "%s\n", e.message );
        }
    }

    public void showPowerStatus()
    {
        try
        {
            IPowerSupply powersupply = Bus.get_proxy_sync<IPowerSupply>( BusType.SYSTEM, FSO_DEVICE_BUS, FSO_DEVICE_PATH );
            int capacity = powersupply.get_capacity();
            string stats = powersupply.get_power_status();
            stdout.printf( "%d%% - %s\n", capacity, stats );
        }
        catch ( GLib.Error e )
        {
            stderr.printf( "%s\n", e.message );
        }
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

// vim:ts=4:sw=4:expandtab
