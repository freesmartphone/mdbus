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

    internal const int MOVEMENT_IDLE_THRESHOLD = 20;
    internal const int MOVEMENT_BUSY_THRESHOLD = 50;

    internal const int FLAT_SURFACE_Z_MIDDLE = 1000;
    internal const int FLAT_SURFACE_Z_RADIUS = 100;

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

    private Ternary flat;
    private Ternary landscape;
    private Ternary facedown;
    private Ternary reverse;
    private string orientation;

    private AccelerometerValue[] history;
    private AccelerometerValue acceleration;

    private uint movementIdleThreshold;
    private uint movementBusyThreshold;

    private bool moving = false;

    private uint nextIndex = 0;

    public enum Polarity
    {
        PLUS,
        MINUS,
    }

    public enum Ternary
    {
        UNKNOWN,
        TRUE,
        FALSE,
    }

    public Accelerometer( FsoFramework.Subsystem subsystem )
    {
        this.subsystem = subsystem;

        subsystem.registerServiceName( FsoFramework.Device.ServiceDBusName );
        subsystem.registerServiceObject( FsoFramework.Device.ServiceDBusName,
                                         FsoFramework.Device.OrientationServicePath,
                                         this );
        logger.info( "Created new Orientation object." );

        history = new AccelerometerValue[kHistorySize];
    }

    public override string repr()
    {
        return ( accelerometer != null ) ? "<%s>".printf( Type.from_instance( accelerometer ).name() ) : "";
    }

    private void startAccelerometer()
    {
        if ( accelerometer == null )
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
                    return; // don't call me again
            }

            var classtype = Type.from_name( typename );
            if ( classtype == Type.INVALID  )
            {
                logger.warning( "Can't find plugin for accelerometer device type '%s'".printf( devicetype ) );
                return; // don't call me again
            }

            accelerometer = Object.new( classtype ) as FsoDevice.BaseAccelerometer;
            logger.info( "Ready. Using accelerometer plugin '%s'".printf( devicetype ) );

            accelerometer.setDelegate( this.onAcceleration );

            movementIdleThreshold = config.intValue( Hardware.HW_ACCEL_PLUGIN_NAME, "movement_idle_threshold", Hardware.MOVEMENT_IDLE_THRESHOLD );
            movementBusyThreshold = config.intValue( Hardware.HW_ACCEL_PLUGIN_NAME, "movement_busy_threshold", Hardware.MOVEMENT_BUSY_THRESHOLD );
        }
        accelerometer.start();
    }

    private void stopAccelerometer()
    {
        if ( accelerometer == null )
            return;

        accelerometer.stop();
    }

    internal void onResourceChanged( AccelerometerResource r, bool enabled )
    {
        if ( enabled )
            startAccelerometer();
        else
            stopAccelerometer();
    }

    public void onAcceleration( int[] axis )
    {
        logger.debug( "onAcceleration: acceleration values: %d, %d, %d".printf( axis[0], axis[1], axis[2] ) );

        int x = axis[0];
        int y = axis[1];
        int z = axis[2];

        /*

        // apply lowpass filter to smooth curve
        acceleration.x = (int) Math.lround( x * kFilteringFactor + acceleration.x * (1.0 - kFilteringFactor) );
        history[nextIndex].x = x - acceleration.x;
        acceleration.y = (int) Math.lround( y * kFilteringFactor + acceleration.y * (1.0 - kFilteringFactor) );
        history[nextIndex].y = y - acceleration.y;
        acceleration.z = (int) Math.lround( z * kFilteringFactor + acceleration.z * (1.0 - kFilteringFactor) );
        history[nextIndex].z = z - acceleration.z;

        logger.info( "Current acceleration delta: %d, %d, %d".printf( history[nextIndex].x, history[nextIndex].y, history[nextIndex].z ) );

        uint movement = (uint) Math.sqrtf( (float) ( history[nextIndex].x * history[nextIndex].x ) + ( history[nextIndex].y * history[nextIndex].y ) + ( history[nextIndex].z * history[nextIndex].z ) );

        if ( !moving && movement > movementBusyThreshold )
        {
            logger.debug( "Started moving (%u > %u)...".printf( movement, movementBusyThreshold ) );
            moving = true;
        }

        if ( moving && movement < movementIdleThreshold )
        {
            logger.debug( "Stopped moving (%u < %u)...".printf( movement, movementIdleThreshold ) );
            moving = false;
            generateOrientationSignal( history[nextIndex].x, history[nextIndex].y, history[nextIndex].z );
        }

        // Advance buffer pointer to next position or reset to zero.
        nextIndex = (nextIndex + 1) % kHistorySize;

        */

        var flat = ( intWithinRegion( z, FLAT_SURFACE_Z_MIDDLE, FLAT_SURFACE_Z_RADIUS ) || intWithinRegion( z, -FLAT_SURFACE_Z_MIDDLE, FLAT_SURFACE_Z_RADIUS ) ) ? Ternary.TRUE : Ternary.FALSE;

        var facedown = ( polarity( z ) == Polarity.MINUS ) ? Ternary.TRUE : Ternary.FALSE;
        var landscape = ( polarity( x ) != polarity( y ) ) ? Ternary.TRUE : Ternary.FALSE;
        var reverse = ( polarity( x ) == Polarity.PLUS ) ? Ternary.TRUE : Ternary.FALSE;

        generateOrientationSignal( flat, landscape, facedown, reverse );
    }

    private Polarity polarity( int value )
    {
        return value >= 0 ? Polarity.PLUS : Polarity.MINUS;
    }

    private bool intWithinRegion( int value, int middle, int region )
    {
        int bounds1 = middle - region;
        int bounds2 = middle + region;
        var res = ( bounds1 > bounds2 ) ? value > bounds2 && value < bounds1 : value > bounds1 && value < bounds2;
#if DEBUG
        message( "intWithinRegion: %d, %d, %d. Answer = %s", value, middle, region, res.to_string() );
#endif

        return res; //( value > lowerbounds && value < upperbounds );
    }

    public void generateOrientationSignal( Ternary flat, Ternary landscape, Ternary facedown, Ternary reverse )
    {
        if ( flat == Ternary.TRUE )
        {
            orientation = "flat %s".printf( facedown == Ternary.TRUE ? "facedown" : "faceup" );
        }
        else
        {
            orientation = "held %s %s %s".printf( landscape == Ternary.TRUE ? "landscape" : "portrait",
                                                  facedown == Ternary.TRUE ? "facedown" : "faceup",
                                                  reverse == Ternary.TRUE ? "reverse" : "normal" );
        }

        var signal = "";

        if ( flat != this.flat )
        {
            this.flat = flat;
            signal += flat == Ternary.TRUE ? "flat " : "held ";
        }

        if ( facedown != this.facedown )
        {
            this.facedown = facedown;
            signal += facedown == Ternary.TRUE ? "facedown " : "faceup ";
        }

        // additional info only valid, if not laying flat
        if ( flat == Ternary.FALSE )
        {
            if ( landscape != this.landscape )
            {
                this.landscape = landscape;
                signal += landscape == Ternary.TRUE ? "landscape " : "portrait ";
            }

            if ( reverse != this.reverse )
            {
                this.reverse = reverse;
                signal += reverse == Ternary.TRUE ? "reverse " : "normal ";
            }
        }

        logger.debug( "Full orientation = %s. Sending change signal for %s".printf( orientation, signal ) );
        if ( signal.length > 0 )
        {
            this.orientation_changed( signal );
        }
    }

    // Resource Handling
    

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

/**
 * Implementation of org.freesmartphone.Resource for the Accelerometer Resource
 **/
class AccelerometerResource : FsoDevice.AbstractSimpleResource
{
    internal bool on;

    public AccelerometerResource( FsoFramework.Subsystem subsystem )
    {
        base( "Accelerometer", subsystem );
    }

    public override void _enable()
    {
        if (on)
            return;
        logger.debug( "enabling..." );
        instance.onResourceChanged( this, true );
        on = true;
    }

    public override void _disable()
    {
        if (!on)
            return;
        logger.debug( "disabling..." );
        instance.onResourceChanged( this, false );
        on = false;
    }
}

} /* namespace */

internal Hardware.Accelerometer instance;
internal Hardware.AccelerometerResource accelerometer;


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
    // create accelerometer resource
    accelerometer = new Hardware.AccelerometerResource( subsystem );
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