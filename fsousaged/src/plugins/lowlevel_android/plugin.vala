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

using GLib;

using FsoUsage;

class LowLevel.Android : FsoUsage.LowLevel, FsoFramework.AbstractObject
{
    internal const string MODULE_NAME = "fsousage.lowlevel_android";

    private string screenresumetype;
    private string screenresumecommand;

    construct
    {
        logger.info( "Registering android low level suspend/resume handling" );
        // grab sysfs paths
        var sysfs_root = config.stringValue( "cornucopia", "sysfs_root", "/sys" );
        sys_power_state = Path.build_filename( sysfs_root, "power", "state" );
        // ensure on status
        FsoFramework.FileHandling.write( "on\n", sys_power_state );

        screenresumetype = config.stringValue( MODULE_NAME, "screen_resume_type","kernel");
        screenresumecommand = config.stringValue( MODULE_NAME, "screen_resume_command","");
    }

    private void process_screen_resume()
    {
        if (screenresumetype == "userspace")
        {
            if ( screenresumecommand != "" )
            {
                var ok = Posix.system( screenresumecommand );
                if ( ok != 0 )
                {
                    logger.error( @"Can't execute '$screenresumecommand' - error code $ok" );
                }
                else
                {
                    assert( logger.debug( @"'$screenresumecommand' executed - return code $ok" ) );
                    assert( logger.debug( "resume executed" ) );
                }
            }
            else
            {
                assert( logger.debug(@"empty screen_resume_command") );
            }
        }
        else
        {
            assert( logger.debug(@"unsupported screen_resume_type: $screenresumetype") );
        }
    }

    //
    // public API
    //

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
        assert( logger.debug( "Setting power state 'mem'" ) );
        FsoFramework.FileHandling.write( "mem\n", sys_power_state );
    }

    public ResumeReason resume()
    {
        assert( logger.debug( "Setting power state 'on'" ) );
        FsoFramework.FileHandling.write( "on\n", sys_power_state );
        process_screen_resume();
        // FIXME who differentiates between the reason the user supplies with
        // org.freesmartphone.Usage.Resume and this one?
        return ResumeReason.Unknown;
    }

    public override string repr()
    {
        return "<>";
    }
}

internal string sys_power_state;

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
