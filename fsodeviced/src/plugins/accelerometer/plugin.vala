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

namespace Hardware
{
    internal char[] buffer;
    internal const uint BUFFER_SIZE = 512;

    internal const string HW_ACCEL_PLUGIN_NAME = "fsodevice.accelerometer";

    internal const int kHistorySize = 150;
    internal const float kFilteringFactor = 0.1f;

    internal struct AccelerometerValue
    {
        int x;
        int y;
        int z;
    }

/**
 * Implementation of org.freesmartphone.Device.Orientation for an Accelerometer device
 **/
class Accelerometer : FreeSmartphone.Device.Orientation, FsoFramework.AbstractObject
{
    private FsoFramework.Subsystem subsystem;
    private FsoDevice.BaseAccelerometer accelerometer;

    private string orientation;

    private AccelerometerValue[] history;
    private AccelerometerValue acceleration;

    private uint nextIndex = 0;

    public Accelerometer( FsoFramework.Subsystem subsystem )
    {
        this.subsystem = subsystem;

        subsystem.registerServiceName( FsoFramework.Device.ServiceDBusName );
        subsystem.registerServiceObject( FsoFramework.Device.ServiceDBusName,
                                         FsoFramework.Device.OrientationServicePath,
                                         this );
        logger.info( "Created new Orientation object." );

        history = new AccelerometerValue[kHistorySize];

        Idle.add( onIdle );
    }

    public bool onIdle()
    {
        var devicetype = config.stringValue( Hardware.HW_ACCEL_PLUGIN_NAME, "device_type", "(not set)" );
        var typename = "";

        switch ( devicetype )
        {
            case "lis302":
                typename = "HardwareAccelerometerLis302";
                break;
            default:
                logger.error( "Unknown accelerometer device type '%s'".printf( devicetype ) );
                return false; // don't call me again
        }

        var classtype = Type.from_name( typename );
        if ( classtype == Type.INVALID  )
        {
            logger.warning( "Can't find plugin for accelerometer device type '%s'".printf( devicetype ) );
            return false; // don't call me again
        }

        accelerometer = Object.new( classtype ) as FsoDevice.BaseAccelerometer;
        logger.info( "Ready. Using accelerometer plugin '%s'".printf( devicetype ) );

        accelerometer.setDelegate( this.onAcceleration );

        return false; // don't call me again
    }

    public override string repr()
    {
        return "";
        //return "<%s>".printf( sysfsnode );
    }

    public void onAcceleration( int[] axis )
    {
        logger.debug( "Received acceleration values: %d, %d, %d".printf( axis[0], axis[1], axis[2] ) );

        int x = axis[0];
        int y = axis[1];
        int z = axis[2];

        // apply lowpass filter to smooth curve
        acceleration.x = (int) Math.lround( x * kFilteringFactor + acceleration.x * (1.0 - kFilteringFactor) );
        history[nextIndex].x = x - acceleration.x;
        acceleration.y = (int) Math.lround( y * kFilteringFactor + acceleration.y * (1.0 - kFilteringFactor) );
        history[nextIndex].y = y - acceleration.y;
        acceleration.z = (int) Math.lround( z * kFilteringFactor + acceleration.z * (1.0 - kFilteringFactor) );
        history[nextIndex].z = z - acceleration.z;

        logger.info( "Current acceleration delta: %d, %d, %d".printf( history[nextIndex].x, history[nextIndex].y, history[nextIndex].z ) );

        // Advance buffer pointer to next position or reset to zero.
        nextIndex = (nextIndex + 1) % kHistorySize;
    }

    //
    // FsoFramework.Device.Orientation (DBUS)
    //
    public HashTable<string,Value?> get_info()
    {
        var dict = new HashTable<string,Value?>( str_hash, str_equal );
        return dict;
    }

    public string get_orientation()
    {
        return orientation;
    }
}

} /* namespace */

internal Hardware.Accelerometer instance;


/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    // create one and only instance
    instance = new Hardware.Accelerometer( subsystem );
    return Hardware.HW_ACCEL_PLUGIN_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    debug( "fsodeviced.accelerometer fso_register_function()" );
}

/**
 * This function gets called on plugin load time.
 * @return false, if the plugin operating conditions are present.
 * @note Some versions of glib contain a bug that leads to a SIGSEGV
 * in g_module_open, if you return true here.
 **/
/*public static bool g_module_check_init( void* m )
{
    var ok = FsoFramework.FileHandling.isPresent( Kernel26.SYS_CLASS_LEDS );
    return (!ok);
}
*/