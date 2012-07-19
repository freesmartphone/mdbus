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

GLib.MainLoop mainloop;

FsoFramework.Subsystem subsystem;
bool use_session_bus = false;
bool show_version = false;

public static void sighandler( int signum )
{
    Posix.signal( signum, null ); // restore original sighandler
#if LINUX_HAVE_BACKTRACE
    var backtrace = FsoFramework.Utility.createBacktrace();
    foreach ( var line in backtrace )
    {
        FsoFramework.theLogger.error( line );
    }
#endif
    FsoFramework.theLogger.info( "received signal -%d, shutting down...".printf( signum ) );
    subsystem.shutdown();
    mainloop.quit();
}

const OptionEntry[] options =
{
    { "test", 't', 0, OptionArg.NONE, ref use_session_bus, "Operate on DBus session bus for testing purpose", null },
    { "version", 'v', 0, OptionArg.NONE, ref show_version, "Display version number", null },
    { null }
};

public static int main( string[] args )
{
    try
    {
        var opt_context = new OptionContext( "" );
        opt_context.set_summary( "FreeSmartphone.org Usage daemon" );
        opt_context.set_description( "This daemon implements the freesmartphone.org Usage API" );
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

    if ( show_version )
    {
        stdout.printf( "fsousaged %s\n".printf( Config.PACKAGE_VERSION ) );
        return 1;
    }

    var bus_type = use_session_bus ? BusType.SESSION : BusType.SYSTEM;

    subsystem = new FsoFramework.DBusSubsystem( "fsousage", bus_type );
    subsystem.registerPlugins();
    uint count = subsystem.loadPlugins();
    FsoFramework.theLogger.info( "loaded %u plugins".printf( count ) );
    if ( count > 0 )
    {
        mainloop = new GLib.MainLoop( null, false );
        FsoFramework.theLogger.info( "fsousaged => mainloop" );
        Posix.signal( Posix.SIGINT, sighandler );
        Posix.signal( Posix.SIGTERM, sighandler );
        Posix.signal( Posix.SIGBUS, sighandler );
        Posix.signal( Posix.SIGSEGV, sighandler );

        /*
        var ok = FsoFramework.UserGroupHandling.switchToUserAndGroup( "nobody", "nogroup" );
        if ( !ok )
            FsoFramework.theLogger.warning( "Unable to drop privileges." );
        */

        mainloop.run();
        FsoFramework.theLogger.info( "mainloop => fsousaged" );
    }
    FsoFramework.theLogger.info( "fsousaged exit" );
    return 0;
}

// vim:ts=4:sw=4:expandtab
