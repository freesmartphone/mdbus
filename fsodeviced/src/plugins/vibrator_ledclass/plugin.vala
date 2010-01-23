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

namespace Vibrator
{

class LedClass : FreeSmartphone.Device.Vibrator, FsoFramework.AbstractObject
{
    FsoFramework.Subsystem subsystem;

    private int max_brightness;
    private string sysfsnode;
    private string brightness;

    private uint fulltimeoutwatch;
    private uint smalltimeoutwatch;
    private uint don;
    private uint doff;
    private bool on;

    static uint counter;

    public LedClass( FsoFramework.Subsystem subsystem, string sysfsnode )
    {
        this.subsystem = subsystem;
        this.sysfsnode = sysfsnode;
        this.max_brightness = FsoFramework.FileHandling.read( this.sysfsnode + "/max_brightness" ).to_int();
        if ( max_brightness == 0 )
        {
            max_brightness = 255;
        }

        this.brightness = sysfsnode + "/brightness";

        if ( !FsoFramework.FileHandling.isPresent( this.brightness ) )
        {
            logger.error( "^^^ sysfs class is damaged; skipping." );
            return;
        }

        subsystem.registerServiceName( FsoFramework.Device.ServiceDBusName );
        subsystem.registerServiceObjectWithPrefix(
            FsoFramework.Device.ServiceDBusName,
            FsoFramework.Device.VibratorServicePath,
            this );
        logger.info( "Created" );
    }

    public override string repr()
    {
        return @"<$sysfsnode>";
    }

    private int _valueToPercent( int value )
    {
        double max = max_brightness;
        double v = value;
        return (int)(100.0 / max * v);
    }

    private int _percentToValue( int percent )
    {
        double p = percent;
        double max = max_brightness;
        double value;
        if ( percent >= 100 )
            value = max_brightness;
        else if ( percent <= 0 )
            value = 0;
        else
            value = p / 100.0 * max;
        return (int)value;
    }

    private void set_brightness( int brightness )
    {
        message( "set brightness to %d", brightness );
        var percent = _percentToValue( brightness );
        FsoFramework.FileHandling.write( percent.to_string(), this.brightness );
        on = ( percent > 0 );
    }

    private bool onToggleTimeout()
    {
        if ( !on )
        {
            set_brightness( 100 );
            smalltimeoutwatch = Timeout.add( don, onToggleTimeout );
        }
        else
        {
            set_brightness( 0 );
            smalltimeoutwatch = Timeout.add( doff, onToggleTimeout );
        }
        return false;
    }

    private void cleanTimeouts()
    {
        if ( smalltimeoutwatch > 0 )
        {
            Source.remove( smalltimeoutwatch );
            smalltimeoutwatch = 0;
        }
        if ( fulltimeoutwatch > 0 )
        {
            Source.remove( fulltimeoutwatch );
            fulltimeoutwatch = 0;
        }
    }
    
    //
    // FreeSmartphone.Device.Vibrator (DBUS API)
    //
    public async string get_name() throws DBus.Error
    {
        return Path.get_basename( sysfsnode );
    }

    public async void vibrate_pattern( int seconds, int delay_on, int delay_off ) throws FreeSmartphone.Error, DBus.Error
    {
        if ( fulltimeoutwatch > 0 )
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Already vibrating... please try again" );
        if ( seconds < 1 )
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Vibration timeout needs to be at least 1 second" );
        if ( delay_on < 50 )
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Delay on duration needs to be at least 50 milliseconds" );
        if ( delay_off < 50 )
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Delay off duration needs to be at least 50 milliseconds" );

        this.don = delay_on;
        this.doff = delay_off;

        fulltimeoutwatch = Timeout.add_seconds( seconds, () => {
            cleanTimeouts();
            set_brightness( 0 );
            return false;
        } );
        onToggleTimeout();
    }

    public async void vibrate( int milliseconds ) throws FreeSmartphone.Error, DBus.Error
    {
        if ( fulltimeoutwatch > 0 )
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Already vibrating... please try again" );
        if ( milliseconds < 50 )
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Vibration timeout needs to be at least 50 milliseconds" );

        cleanTimeouts();
        set_brightness( 100 );
        fulltimeoutwatch = Timeout.add( milliseconds, () => {
            cleanTimeouts();
            set_brightness( 0 );
            return false;
        } );
    }

    public async void stop() throws FreeSmartphone.Error, DBus.Error
    {
        cleanTimeouts();
        set_brightness( 0 );
    }
}

} /* namespace */

static string sysfs_root;
static string sys_class_net;
static string sys_class_leds;
List<Vibrator.LedClass> instances;

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    // grab sysfs paths
    var config = FsoFramework.theConfig;
    sysfs_root = config.stringValue( "cornucopia", "sysfs_root", "/sys" );
    sys_class_leds = "%s/class/leds".printf( sysfs_root );
    sys_class_net = "%s/class/net".printf( sysfs_root );

    // scan sysfs path for leds
    var dir = Dir.open( sys_class_leds );
    var entry = dir.read_name();
    while ( entry != null )
    {
#if FOO
        if ( "thinklight" in entry )
#endif
        {
            var filename = Path.build_filename( sys_class_leds, entry );
            instances.append( new Vibrator.LedClass( subsystem, filename ) );
        }
        entry = dir.read_name();
    }
    return "fsodevice.vibrator_ledclasss";
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsodevice.vibrator_ledclasss fso_register_function()" );
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
