/*
 * (C) 2011-2012 Michael 'Mickey' Lauer <mickey@vanille-media.de>
 *          Simon Busch <morphis@gravedo.de>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */

GLib.MainLoop mainloop;
bool use_session_bus = false;
bool show_version = false;

public static void sighandler( int signum )
{
    Posix.signal( signum, null ); // restore original sighandler
    FsoFramework.theLogger.info( "Received signal -%d, exiting.".printf( signum ) );
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
        opt_context.set_summary( "FreeSmartphone.org Audio daemon" );
        opt_context.set_description( "This daemon implements the freesmartphone.org Audio API" );
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
        stdout.printf( "fsodeviced %s\n".printf( Config.PACKAGE_VERSION ) );
        return 1;
    }

    var bus_type = use_session_bus ? BusType.SESSION : BusType.SYSTEM;
    var subsystem = new FsoFramework.DBusSubsystem( "fsoaudio", bus_type );
    subsystem.registerPlugins();
    uint count = subsystem.loadPlugins();
    FsoFramework.theLogger.info( "loaded %u plugins".printf( count ) );
    if ( count > 0 )
    {
        mainloop = new GLib.MainLoop( null, false );
        FsoFramework.theLogger.info( "fsoaudiod => mainloop" );
        Posix.signal( Posix.SIGINT, sighandler );
        Posix.signal( Posix.SIGTERM, sighandler );
        // enable for release version?
        //Posix.signal( Posix.SIGBUS, sighandler );
        //Posix.signal( Posix.SIGSEGV, sighandler );
        mainloop.run();
        FsoFramework.theLogger.info( "mainloop => fsoaudiod" );
    }
    FsoFramework.theLogger.info( "fsoaudiod shutdown." );
    return 0;
}

// vim:ts=4:sw=4:expandtab
