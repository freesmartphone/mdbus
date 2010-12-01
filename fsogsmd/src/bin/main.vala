/*
 * Copyright (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

public static int main( string[] args )
{
    var bin = FsoFramework.Utility.programName();
    subsystem = new FsoFramework.DBusSubsystem( "fsogsm" );
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
