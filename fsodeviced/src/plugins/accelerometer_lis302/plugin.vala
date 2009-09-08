/**
 * Copyright (C) 2009 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

class AccelerometerLis302 : FsoDevice.BaseAccelerometer
{
    private string inputnode;
    private string sysfsnode;
    internal int fd = -1;
    private IOChannel channel;
    private int[] axis;

    construct
    {
        logger.info( "Registering lis302 accelerometer" );
        // grab sysfs paths
        var sysfs_root = config.stringValue( "cornucopia", "sysfs_root", "/sys" );
        var devfs_root = config.stringValue( "cornucopia", "devfs_root", "/dev" );
        inputnode = devfs_root + config.stringValue( HW_ACCEL_LIS302_PLUGIN_NAME, "inputnode", "/input/event2" );
        fd = Posix.open( inputnode, Posix.O_RDONLY );
        if ( fd == -1 )
        {
            logger.warning( "Can't open %s (%s). Lis302 Accelerometer will not be available.".printf( inputnode, Posix.strerror( Posix.errno ) ) );
        }
        else
        {
            Idle.add( onIdle );
        }
        //Timeout.add( 500, feedConstant );

    }

    public bool feedConstant()
    {
        // feed constant value for debugging
        Linux26.Input.Event ev = {};
        ev.type = Linux26.Input.EV_ABS;
        ev.code = 0; // X-AXIS
        ev.value = 0;
        _handleInputEvent( ref ev );
        ev.code = 1; // Y-AXIS
        ev.value = 0;
        _handleInputEvent( ref ev );
        ev.code = 2; // Z-AXIS
        ev.value = 1000; // 1G
        _handleInputEvent( ref ev );

        return true; // call me again
    }

    public override string repr()
    {
        return "<via %s>".printf( inputnode );
    }

    private bool onIdle()
    {
        axis = new int[3];

        channel = new IOChannel.unix_new( fd );
        channel.add_watch( IOCondition.IN, onInputEvent );
        return false; // don't call me again
    }

    private void _handleInputEvent( ref Linux26.Input.Event ev )
    {
        if ( ev.code > 2 )
        {
            logger.warning( "invalid data from input device. axis > 2" );
            return;
        }
        else
        {
            axis[ev.code] = ev.value;
            accelerationFunc( axis );
        }
    }

    public bool onInputEvent( IOChannel source, IOCondition condition )
    {
        Linux26.Input.Event ev = {};
        var bytesread = Posix.read( source.unix_get_fd(), &ev, sizeof(Linux26.Input.Event) );
        if ( bytesread == 0 )
        {
            logger.warning( "could not read from input device fd %d.".printf( source.unix_get_fd() ) );
            return false;
        }

        // we're only interested in the absolute axis values
        if ( ev.type == Linux26.Input.EV_ABS )
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
    debug( "accelerometer_lis302 fso_factory_function" );
    return "fsodeviced.accelerometer_lis302";
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    // do not remove this function
}
