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

using GLib;

using FsoUsage;

class LowLevel.Android : FsoUsage.LowLevel, FsoFramework.AbstractObject
{
    internal const string MODULE_NAME = "fsousage.lowlevel_android";
    internal const int MAX_WAIT_FOR_SLEEP = 2000; /* ms */
    internal const int ERESTARTNOHAND = 514;

    private int fd;

    private int inputnodenumber;
    private int powerkeycode;

    construct
    {
        logger.info( "Registering android low level suspend/resume handling" );
        // grab sysfs paths
        var sysfs_root = config.stringValue( "cornucopia", "sysfs_root", "/sys" );
        sys_power_state = Path.build_filename( sysfs_root, "power", "state" );
        // ensure on status
        FsoFramework.FileHandling.write( "on\n", sys_power_state );

        // which input node to observe for power on key
        inputnodenumber = config.intValue( MODULE_NAME, "wakeup_inputnode", -1 );
        // value of the power on key
        powerkeycode = config.intValue( MODULE_NAME, "wakeup_powerkeycode", -1 );
    }

    public override string repr()
    {
        return "<>";
    }

    /**
     * Android/Linux specific suspend function to cope with Android/Linux differences:
     *
     * 1.) Android/Linux kernels do not suspend synchronously.
     *
     * 2.) When a resume event comes in, they rely on userland to decide whether to
     * fully wake up or fall asleep again.
     *
     **/
    public void suspend()
    {
        assert( logger.debug( "Grabbing input node" ) );
        fd = Posix.open( @"/dev/input/event$inputnodenumber", Posix.O_RDONLY );
        Linux.ioctl( fd, Linux.Input.EVIOCGRAB, 1 );

        while ( true )
        {
            wait_for_early_resume();

            assert( logger.debug( "Checking for action on input node" ) );
            var readfds = Posix.fd_set();
            var writefds = Posix.fd_set();
            var exceptfds = Posix.fd_set();
            Posix.FD_SET( fd, readfds );
            Posix.timeval t = { 5, 0 };
            int res = Posix.select( fd+1, readfds, writefds, exceptfds, t );

            if ( res < 0 || Posix.FD_ISSET( fd, readfds ) == 0 )
            {
                assert( logger.debug( "No action on input device node; seems something else woke us up!" ) );
                break;
            }

            Linux.Input.Event ev = {};
            var bytesread = Posix.read( fd, &ev, sizeof(Linux.Input.Event) );
            if ( bytesread == 0 )
            {
                assert( logger.debug( @"Can't read from fd $fd; waking up!" ) );
                break;
            }

            if ( ev.code == powerkeycode )
            {
                assert( logger.debug( @"Power key; waking up!" ) );
                break;
            }
            else
            {
                assert( logger.debug( @"Some other key w/ value $(ev.code); NOT waking up!" ) );
            }
        }

        assert( logger.debug( "Ungrabbing input nodes" ) );
        Linux.ioctl( fd, Linux.Input.EVIOCGRAB, 0 );
        Posix.close( fd );

        assert( logger.debug( "Setting power state 'on'" ) );
        FsoFramework.FileHandling.write( "on\n", sys_power_state );
    }

    private void wait_for_early_resume()
    {
        int res = 0;

        do
        {
            assert( logger.debug( "Setting power state 'mem'" ) );
            FsoFramework.FileHandling.write( "mem\n", sys_power_state );

            var fds = Posix.fd_set();
            var t = Posix.timeval();
            t.tv_sec = MAX_WAIT_FOR_SLEEP / 1000;
            t.tv_usec = 0;

            res = Posix.select( 0, fds, fds,fds, t );
        }
        while ( res != -ERESTARTNOHAND );
    }

    public ResumeReason resume()
    {
        return ResumeReason.Unknown;
    }

    /*
    public void onInput( void* data, ssize_t length )
    {
        logger.info( "Received wakeup request... waking up" );
        assert( logger.debug( "Ungrabbing input nodes" ) );
        Linux.ioctl( fd, Linux.Input.EVIOCGRAB, 0 );
        assert( logger.debug( "Destroying reactor" ) );
        //reactor = null;
    }
    */
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
    FsoFramework.theLogger.debug( "lowlevel_android fso_factory_function" );
    return LowLevel.Android.MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    // do not remove this function
}
