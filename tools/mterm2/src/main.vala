/*
 * This file is part of mterm2
 *
 * (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 */

//===========================================================================
using GLib;

MainLoop loop;

public class Options
{
    public static int portspeed = 115200;
    public static string portspec;
    public static string[] arguments;

    OptionContext context;

    const OptionEntry[] options = {
        { "portspeed", 's', 0, OptionArg.INT, ref portspeed, "The port speed (bytes per sec) [default=115200]", "PORTSPEED" },
        { "", 0, 0, OptionArg.STRING_ARRAY, ref arguments, "portspec", "<PORTSPEC>" },
        { null }
    };

    public Options()
    {
        context = new OptionContext( "- freesmartphone.org Terminal" );
        context.set_help_enabled( true );
        context.add_main_entries( options, null );
    }

    public void parse( string[] args ) throws OptionError
    {
        context.parse( ref args );
        if ( arguments == null )
            throw new OptionError.BAD_VALUE( "No port specification given." );
        else if ( arguments[1] != null )
            throw new OptionError.BAD_VALUE( "Too many arguments." );
        else
            portspec = arguments[0];
    }
}

//===========================================================================
public static void SIGINT_handler( int signum )
{
    stdout.printf( "Ouch! Press CTRL-D to end the terminal or CTRL-C again to force quitting.\n" );
    Posix.signal( signum, null ); // restore original signal handler
    /*
    if ( loop != null )
        loop.quit();
    */
}

//===========================================================================
public static void quitWithMessage( string message )
{
    stdout.printf( "%s\n", message );
    if ( loop != null )
        loop.quit();
}

//===========================================================================
public static void fsoMessage( string message )
{
    stdout.printf( ":::%s [FSO Terminal %s via %s@%d]\n\n", message, Config.PACKAGE_VERSION, Options.portspec, Options.portspeed );
}

//===========================================================================
public int main( string[] args )
{
    loop = new MainLoop( null, false );
    Posix.signal( Posix.SIGINT, SIGINT_handler );

    var o = new Options();
    try
    {
        o.parse( args );
    }
    catch ( OptionError e )
    {
        stdout.printf( "%s\n", e.message );
        stdout.printf( "Run '%s --help' to see a full list of available command line options.\n", args[0] );
        return 1;
    }

    var terminal = new Terminal( o );

    /*
    try
    {
        var conn = DBus.Bus.get( DBus.BusType.SYSTEM );

        dynamic DBus.Object bus = conn.get_object( DBUS_BUS_NAME, DBUS_OBJ_PATH, DBUS_INTERFACE );
        // try to register service in session bus
        uint request_name_result = bus.request_name( MUXER_BUS_NAME, (uint) 0 );

        if ( request_name_result == DBus.RequestNameReply.PRIMARY_OWNER )
        {
            Log.set_handler( null, LogLevelFlags.LEVEL_DEBUG, LOG_handler );
            Posix.signal( Posix.SIGINT, SIGINT_handler );

            server = new Server();
            conn.register_object( MUXER_OBJ_PATH, server );
            debug( "=> mainloop" );
            loop.run();
            debug( "<= mainloop" );
            server = null;
        }
        else
        {
            error( "Can't register bus name. Service already started?\n" );
        }
    } catch (Error e) {
        error( "Oops: %s", e.message );
    }
    */

    fsoMessage( "Welcome." );
    Idle.add( terminal.open );
    loop.run();
    fsoMessage( "Goodbye." );
    Readline.free_line_state();
    Readline.cleanup_after_signal();

    return 0;
}

