/*
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

using GLib;

using FsoUsage;

class LowLevel.Kernel26_StaysAlive : FsoUsage.LowLevel, FsoFramework.AbstractObject
{
    private int fd;

    construct
    {
        logger.info( "Registering kernel26_staysalive low level suspend/resume handling" );
        // grab sysfs paths
        var sysfs_root = config.stringValue( "cornucopia", "sysfs_root", "/sys" );
        sys_power_state = Path.build_filename( sysfs_root, "power", "state" );
        // ensure on status
        FsoFramework.FileHandling.write( "on\n", sys_power_state );
    }

    public override string repr()
    {
        return "<>";
    }

    public void suspend()
    {
        assert( logger.debug( "Setting power state 'mem'" ) );
        FsoFramework.FileHandling.write( "mem\n", sys_power_state );

        assert( logger.debug( "Grabbing input nodes" ) );
        var fd = Posix.open( "/dev/input/event3", Posix.O_RDONLY );
        Linux.ioctl( fd, Linux.Input.EVIOCGRAB, 1 );

        assert( logger.debug( "Waiting for action on input node" ) );
        var readfds = Posix.fd_set();
        var writefds = Posix.fd_set();
        var exceptfds = Posix.fd_set();
        Posix.FD_SET( fd, readfds );
        Posix.timeval t = { 60*60*24, 0 };
        int res = Posix.select( fd+1, readfds, writefds, exceptfds, t ); // block indefinitely

        assert( logger.debug( "ACTION! Ungrabbing input nodes" ) );
        Linux.ioctl( fd, Linux.Input.EVIOCGRAB, 0 );

        assert( logger.debug( "Setting power state 'on'" ) );
        FsoFramework.FileHandling.write( "on\n", sys_power_state );

        /*
        if ( res < 0 || Posix.FD_ISSET( fd, readfds ) == 0 )
            return 0;
        ssize_t bread = Posix.read( fd, rdata, rlength );
        return (int)bread;
        */


        /*
        assert( logger.debug( "Creating reactor" ) );
        input = new Async.ReactorChannel( fd, onInput, sizeof( Linux.Input.Event ) );
        */
    }

    public ResumeReason resume()
    {
        return ResumeReason.Unknown;
    }





    public void onInput( void* data, ssize_t length )
    {
        logger.info( "Received wakeup request... waking up" );
        assert( logger.debug( "Ungrabbing input nodes" ) );
        Linux.ioctl( fd, Linux.Input.EVIOCGRAB, 0 );
        assert( logger.debug( "Destroying reactor" ) );
        //reactor = null;
    }
}

string sys_power_state;

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    FsoFramework.theLogger.debug( "lowlevel_kernel26_staysalive fso_factory_function" );
    return "fsousage.lowlevel_kernel26_staysalive";
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    // do not remove this function
}

// vim:ts=4:sw=4:expandtab
