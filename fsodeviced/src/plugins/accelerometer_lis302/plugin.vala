/**
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

namespace Hardware {

    internal const string HW_ACCEL_LIS302_PLUGIN_NAME = "fsodevice.accelerometer_lis302";
    internal const string DEFAULT_EVENT_NODE = "/input/event2";
    internal const string LIS302_CONFIGURATION_NODE = "/bus/spi/drivers/lis302dl/spi3.0";

    internal const int LIS302_DEFAULT_SAMPLERATE = 100;
    internal const int LIS302_DEFAULT_THRESHOLD = 100;
    internal const string LIS302_DEFAULT_FULLSCALE = "2.3";

class AccelerometerLis302 : FsoDevice.BaseAccelerometer
{
    private string inputnode;
    private string sysfsnode;

    private uint sample_rate;
    private uint threshold;
    private string full_scale;

    internal int fd = -1;
    private IOChannel channel;
    private uint watch;
    private int[] axis;

    private uint timeout;


    construct
    {
        logger.info( "Registering lis302 accelerometer" );
        // grab sysfs paths
        var sysfs_root = config.stringValue( "cornucopia", "sysfs_root", "/sys" );
        var devfs_root = config.stringValue( "cornucopia", "devfs_root", "/dev" );
        inputnode = devfs_root + config.stringValue( HW_ACCEL_LIS302_PLUGIN_NAME, "inputnode", "/input/event2" );
        sysfsnode = sysfs_root + LIS302_CONFIGURATION_NODE;

        sample_rate = config.intValue( HW_ACCEL_LIS302_PLUGIN_NAME, "sample_rate", LIS302_DEFAULT_SAMPLERATE );
        threshold = config.intValue( HW_ACCEL_LIS302_PLUGIN_NAME, "threshold", LIS302_DEFAULT_THRESHOLD );
        full_scale = config.stringValue( HW_ACCEL_LIS302_PLUGIN_NAME, "full_scale", LIS302_DEFAULT_FULLSCALE );

        if ( !FsoFramework.FileHandling.isPresent( sysfsnode ) )
        {
            logger.warning( "Lis302 configuration sysfs not available at %s. Accelerometer will not work properly.".printf( sysfsnode ) );
        }
        else
        {
            FsoFramework.FileHandling.write( sample_rate.to_string(), sysfsnode + "/sample_rate" );
            FsoFramework.FileHandling.write( threshold.to_string(), sysfsnode + "/threshold" );
            FsoFramework.FileHandling.write( full_scale, sysfsnode + "/full_scale" );
        }
        axis = new int[3];
    }

    public override string repr()
    {
        return "<via %s>".printf( inputnode );
    }

    private bool feedImpulse()
    {
        axis[0] = 0;
        axis[1] = 0;
        axis[2] = 0;

        this.accelerate( axis[0], axis[1], axis[2] ); // GOBJECT SIGNAL
        return false;
    }

    public override void start()
    {
        fd = Posix.open( inputnode, Posix.O_RDONLY );
        if ( fd == -1 )
        {
            logger.warning( @"Can't open $inputnode: $(strerror(errno)) Lis302 Accelerometer not available." );
            return;
        }
        channel = new IOChannel.unix_new( fd );
        watch = channel.add_watch( IOCondition.IN, onInputEvent );
    }

    public override void stop()
    {
        if ( watch > 0 )
        {
            Source.remove( watch );
        }
        channel = null;
        if ( fd != -1 )
        {
            Posix.close( fd );
        }
        fd = -1;
    }

    private bool onTimeout()
    {
        this.accelerate( axis[0], axis[1], axis[2] ); // GOBJECT SIGNAL
        timeout = 0;
        return false; // don't call me again
    }

    private void _handleInputEvent( ref Linux.Input.Event ev )
    {
        if ( ev.code > 2 )
        {
            logger.warning( "Invalid data from input device. axis > 2" );
            return;
        }

        axis[ev.code] = ev.value;
        if ( timeout != 0 )
        {
            Source.remove( timeout );
        }
        timeout = Timeout.add_seconds( 1, onTimeout );
    }

    public bool onInputEvent( IOChannel source, IOCondition condition )
    {
        Linux.Input.Event ev = {};
        var bytesread = Posix.read( source.unix_get_fd(), &ev, sizeof(Linux.Input.Event) );
        if ( bytesread == 0 )
        {
            logger.warning( "could not read from input device fd %d.".printf( source.unix_get_fd() ) );
            return false;
        }

        // we're only interested in the absolute axis values
        if ( ev.type == Linux.Input.EV_ABS )
        {
            logger.debug( "input ev %d, %d, %d, %d".printf( source.unix_get_fd(), ev.type, ev.code, ev.value ) );
            _handleInputEvent( ref ev );
        }
#if DEBUG
        else
        {
            logger.debug( "(ignoring non-ABS) input ev %d, %d, %d, %d".printf( source.unix_get_fd(), ev.type, ev.code, ev.value ) );
        }
#endif

        return true;
    }
}

} /* namespace Hardware */

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    return "fsodevice.accelerometer_lis302";
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsodevice.accelerometer_lis302 fso_register_function" );
}
