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

class LowLevel.Android : FsoUsage.LowLevel, FsoFramework.AbstractObject
{
    internal const string MODULE_NAME = "fsousage.lowlevel_android";
    internal const int MAX_WAIT_FOR_SLEEP = 2000; /* ms */
    internal const int ERESTARTNOHAND = 514;

    private int fd;

    private int inputnodenumber;
    private int powerkeycode;
    private string screenresumetype;
    private string screenresumecommand;
    string reason = "unknown";

    construct
    {
        logger.info( "Registering android low level suspend/resume handling" );
        // grab sysfs paths
        var sysfs_root = config.stringValue( "cornucopia", "sysfs_root", "/sys" );
        sys_power_state = Path.build_filename( sysfs_root, "power", "state" );
        // grab procfs paths
        proc_wakelocks_suspend_resume = "/proc/wakelocks_suspend_resume";
        proc_wakelocks_resume_reason = "/proc/wakelocks_resume_reason";
        // ensure on status
        FsoFramework.FileHandling.write( "on\n", sys_power_state );

        // which input node to observe for power on key
        inputnodenumber = config.intValue( MODULE_NAME, "wakeup_inputnode", -1 );
        // value of the power on key
        powerkeycode = config.intValue( MODULE_NAME, "wakeup_powerkeycode", -1 );
        screenresumetype = config.stringValue( MODULE_NAME, "screen_resume_type","kernel");
        screenresumecommand = config.stringValue( MODULE_NAME, "screen_resume_command","");
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

        assert( logger.debug( "Setting power state 'mem'" ) );
        FsoFramework.FileHandling.write( "mem\n", sys_power_state );

        while ( true )
        {
            var readfds = Posix.fd_set();
            var writefds = Posix.fd_set();
            var exceptfds = Posix.fd_set();
            Posix.FD_SET( fd, readfds );
            Posix.timeval t = { 1, 0 };
            int res = Posix.select( fd+1, readfds, writefds, exceptfds, t );

            if ( res < 0 || Posix.FD_ISSET( fd, readfds ) == 0 )
            {
                assert( logger.debug( "No action on input device node; continuing to sleep" ) );
                continue;
            }

            Linux.Input.Event ev = {};
            var bytesread = Posix.read( fd, &ev, sizeof(Linux.Input.Event) );
            if ( bytesread == 0 )
            {
                assert( logger.debug( @"Action on input node, but can't read from fd $fd; waking up!" ) );
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
                continue;
            }
        }

        assert( logger.debug( "Ungrabbing input node" ) );
        Linux.ioctl( fd, Linux.Input.EVIOCGRAB, 0 );
        Posix.close( fd );

        assert( logger.debug( "Setting power state 'on'" ) );
        FsoFramework.FileHandling.write( "on\n", sys_power_state );

        if (screenresumetype == "userspace")
        {
            if ( screenresumecommand != "" )
            {
                var ok = Posix.system( screenresumecommand );
                if ( ok != 0 )
                {
                    logger.error( @"Can't execute '$screenresumecommand' - error code $ok" );
                }else{
                    logger.debug( @"'$screenresumecommand' executed - return code $ok" );
                    logger.debug( "resume executed" );
                }
            }else{
                logger.debug(@"empty screen_resume_command");
            }
        }else
        {
            logger.debug(@"unsupported screen_resume_type: $screenresumetype");
        }

    }


    public ResumeReason resume()
    {
        return ResumeReason.PowerKey;

        if ( reason.has_prefix( "event" ) )
        {
            return ResumeReason.PowerKey;
        }
        else if ( reason == "SMD_RPCCALL" )
        {
            return ResumeReason.PMU;
        }
        return ResumeReason.Unknown;
    }

}

internal string sys_power_state;
internal string proc_wakelocks_suspend_resume;
internal string proc_wakelocks_resume_reason;

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

// vim:ts=4:sw=4:expandtab
