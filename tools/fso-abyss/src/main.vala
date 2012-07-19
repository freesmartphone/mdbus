/*
 * main.vala
 *
 * (C) 2009-2012 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

using CONST;

//===========================================================================
Server server;
MainLoop loop;
FsoFramework.Logger logger;

//===========================================================================
public static void SIGINT_handler( int signum )
{
    Posix.signal( signum, null ); // restore original signal handler
    logger.info( "received signal -%d, exiting.".printf( signum ) );
    if ( server != null )
    {
        try
        {
            server.CloseSession();
        }
        catch ( Error e )
        {
            logger.error( @"Oops: $(e.message)" );
        }
        loop.quit();
    }
}

//===========================================================================
void main()
{
    var bin = FsoFramework.Utility.programName();
    logger = FsoFramework.theLogger;
    logger.info( "%s starting up...".printf( bin ) );
    loop = new MainLoop();

    try
    {
        var conn = DBus.Bus.get( DBus.BusType.SYSTEM );

        dynamic DBus.Object bus = conn.get_object( DBUS_BUS_NAME, DBUS_OBJ_PATH, DBUS_INTERFACE );
        // try to register service in session bus
        uint request_name_result = bus.request_name( MUXER_BUS_NAME, (uint) 0 );

        if ( request_name_result == DBus.RequestNameReply.PRIMARY_OWNER )
        {
            Posix.signal( Posix.SIGINT, SIGINT_handler );
            server = new Server();
            conn.register_object( MUXER_OBJ_PATH, server );
            loop.run();
            server = null;
        }
        else
        {
            logger.error( "Can't register bus name. Service already started?\n" );
        }
    }
    catch (Error e)
    {
        logger.error( @"Oops: $(e.message)" );
    }
}

// vim:ts=4:sw=4:expandtab
