/*
 * (C) 2011-2012 Michael 'Mickey' Lauer <mickey@vanille-media.de>
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

public static void sighandler( int signum )
{
    Posix.signal( signum, null ); // restore original sighandler
    FsoFramework.theLogger.info( "Received signal -%d, exiting.".printf( signum ) );
    mainloop.quit();
}

public static int main( string[] args )
{
    var subsystem = new FsoFramework.DBusSubsystem( "fsophone" );
    subsystem.registerPlugins();
    uint count = subsystem.loadPlugins();
    FsoFramework.theLogger.info( "loaded %u plugins".printf( count ) );
    if ( count > 0 )
    {
        mainloop = new GLib.MainLoop( null, false );
        FsoFramework.theLogger.info( "fsophoned => mainloop" );
        Posix.signal( Posix.SIGINT, sighandler );
        Posix.signal( Posix.SIGTERM, sighandler );
        // enable for release version?
        //Posix.signal( Posix.SIGBUS, sighandler );
        //Posix.signal( Posix.SIGSEGV, sighandler );
        mainloop.run();
        FsoFramework.theLogger.info( "mainloop => fsophoned" );
    }
    FsoFramework.theLogger.info( "fsophoned shutdown." );
    return 0;
}

// vim:ts=4:sw=4:expandtab
