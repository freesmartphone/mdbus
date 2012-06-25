/*
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 */

GLib.MainLoop mainloop;

FsoFramework.Subsystem subsystem;

public static void sighandler( int signum )
{
    Posix.signal( signum, null ); // restore original sighandler
    FsoFramework.theLogger.info( "received signal -%d, exiting.".printf( signum ) );
    Idle.add( () => {
        subsystem.shutdown();
        mainloop.quit();
        return false;
    } );
}

bool use_session_bus = false;

const OptionEntry[] options =
{
    { "test", 's', 0, OptionArg.NONE, ref use_session_bus, "Operate on DBus session bus for testing purpose", null },
    { null }
};

public static int main( string[] args )
{
    try
    {
        var opt_context = new OptionContext( "" );
        opt_context.set_summary( "FreeSmartphone.org GSM daemon" );
        opt_context.set_description( "This daemon implements the freesmartphone.org GSM API" );
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

    var bin = FsoFramework.Utility.programName();
    var bus_type = use_session_bus ? BusType.SESSION : BusType.SYSTEM;
    subsystem = new FsoFramework.DBusSubsystem( "fsogsm", bus_type );
    subsystem.registerPlugins();
    uint count = subsystem.loadPlugins();
    FsoFramework.theLogger.info( "loaded %u plugins".printf( count ) );
    if ( count > 0 )
    {
        mainloop = new GLib.MainLoop( null, false );
        FsoFramework.theLogger.info( "%s => mainloop".printf( bin ) );
        Posix.signal( Posix.SIGINT, sighandler );
        Posix.signal( Posix.SIGTERM, sighandler );
        Posix.signal( Posix.SIGBUS, sighandler );
        Posix.signal( Posix.SIGSEGV, sighandler );

        /*
        var ok = FsoFramework.UserGroupHandling.switchToUserAndGroup( "nobody", "nogroup" );
        if ( !ok )
        logger.warning( "Unable to drop privileges." );
        */

        mainloop.run();
        FsoFramework.theLogger.info( "mainloop => %s".printf( bin ) );
    }
    FsoFramework.theLogger.info( "%s exit".printf( bin ) );
    return 0;
}

// vim:ts=4:sw=4:expandtab
