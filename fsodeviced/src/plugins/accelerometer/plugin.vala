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

namespace Hardware
{
    internal const string HW_ACCEL_PLUGIN_NAME = "fsodevice.accelerometer";

    internal const int DEFAULT_DEADZONE = 180;
    internal const int DEFAULT_DELAY = 1000;

/**
 * Implementation of org.freesmartphone.Device.Orientation for an Accelerometer device
 **/
class Accelerometer : FreeSmartphone.Device.Orientation,
                      FreeSmartphone.Info,
                      FsoFramework.AbstractObject
{
    public static FsoDevice.BaseAccelerometer accelerometer;

    private FsoFramework.Subsystem subsystem;

    private int deadzone;
    private int delay;
    private uint timeout;

    private bool flat;
    private bool landscape;
    private bool faceup;
    private bool reverse;
    private string orientation;

    public enum Ternary
    {
        UNKNOWN,
        TRUE,
        FALSE,
    }

    public Accelerometer( FsoFramework.Subsystem subsystem )
    {
        this.subsystem = subsystem;

        subsystem.registerObjectForService<FreeSmartphone.Info>( FsoFramework.Device.ServiceDBusName, FsoFramework.Device.OrientationServicePath, this );
        subsystem.registerObjectForService<FreeSmartphone.Device.Orientation>( FsoFramework.Device.ServiceDBusName, FsoFramework.Device.OrientationServicePath, this );

        deadzone = config.intValue( HW_ACCEL_PLUGIN_NAME, "deadzone", DEFAULT_DEADZONE);
        delay = config.intValue( HW_ACCEL_PLUGIN_NAME, "delay", DEFAULT_DELAY);

        generateOrientationSignal( false, false, true, false );
        logger.info( "Created new Orientation object." );
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
                case "kxsd9":
                    typename = "HardwareAccelerometerKxsd9";
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

            accelerometer.accelerate.connect( this.onAcceleration );
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

    public void onAcceleration( int x, int y, int z )
    {
#if DEBUG
        message( @"onAcceleration: acceleration values: $x, $y, $z" ) );
#endif

        var xpol = polarity( x );
        var ypol = polarity( y );
        var zpol = polarity( z );

        bool flat = ( xpol == Ternary.UNKNOWN && ypol == Ternary.UNKNOWN ? true : false );
        bool faceup = ( zpol == Ternary.UNKNOWN ? this.faceup : zpol == Ternary.TRUE );
        bool landscape = ( xpol == Ternary.UNKNOWN || ypol == Ternary.UNKNOWN ? this.landscape
                         : ( xpol != ypol ? true : false ) );
        bool reverse = ( xpol == Ternary.UNKNOWN ? this.reverse : xpol == Ternary.TRUE );

        generateOrientationSignal( flat, landscape, faceup, reverse );
    }

    private Ternary polarity( int value )
    {
        if ( value < -deadzone || value > deadzone )
            return ( value > 0 ? Ternary.TRUE : Ternary.FALSE );

        return Ternary.UNKNOWN;
    }

    public void generateOrientationSignal( bool flat, bool landscape, bool faceup, bool reverse )
    {
        bool change = (flat      != this.flat      || faceup  != this.faceup ||
                       landscape != this.landscape || reverse != this.reverse );

        orientation = "%s %s %s %s".printf( flat      ? "flat"      : "held",
                                            faceup    ? "faceup"    : "facedown",
                                            landscape ? "landscape" : "portrait",
                                            reverse   ? "reverse"   : "normal" );

        this.flat      = flat;
        this.faceup    = faceup;
        this.landscape = landscape;
        this.reverse   = reverse;

        if ( !change )
            return;

        if ( delay == 0 )
        {
            this.orientation_changed( orientation );
            return;
        }

        if ( timeout != 0 )
            Source.remove( timeout );
        timeout = Timeout.add( delay, onTimeout );
    }

    private bool onTimeout()
    {
        this.orientation_changed( orientation );
        timeout = 0;
        return false;
    }

    //
    // FreeSmartphone.Info (DBUS)
    //
    public async HashTable<string,Variant> get_info() throws DBusError, IOError
    {
        //FIXME: implement
        var dict = new HashTable<string,Variant>( str_hash, str_equal );
        return dict;
    }

    //
    // FreeSmartphone.Device.Orientation (DBUS)
    //
    public async string get_orientation()
    {
        return orientation;
    }
}

/**
 * Implementation of org.freesmartphone.Resource for the Accelerometer Resource
 **/
class AccelerometerResource : FsoFramework.AbstractDBusResource
{
    internal bool on;

    public AccelerometerResource( FsoFramework.Subsystem subsystem )
    {
        base( "Accelerometer", subsystem );
    }

    public override async void enableResource()
    {
        if (on)
            return;
        logger.debug( "enabling..." );
        instance.onResourceChanged( this, true );
        on = true;
    }

    public override async void disableResource()
    {
        if (!on)
            return;
        logger.debug( "disabling..." );
        instance.onResourceChanged( this, false );
        on = false;
    }

    public override async void suspendResource()
    {
        logger.debug( "suspending..." );
    }

    public override async void resumeResource()
    {
        logger.debug( "resuming..." );
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
    FsoFramework.theLogger.debug( "fsodevice.accelerometer fso_register_function()" );
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

// vim:ts=4:sw=4:expandtab
