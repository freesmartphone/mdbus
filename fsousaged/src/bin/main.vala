/*
 * Copyright (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

public static int main( string[] args )
{
    subsystem = new FsoFramework.DBusSubsystem( "fsousage" );
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
