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

namespace Vibrator
{

class OmapVibe : FreeSmartphone.Device.Vibrator, FsoFramework.AbstractObject
{
    FsoFramework.Subsystem subsystem;

    private string sysfsnode;
    private string direction;

    private int max_strength;

    private uint fulltimeoutwatch;
    private uint smalltimeoutwatch;
    private uint don;
    private uint doff;
    private bool on;
    private int pulses;
    private int strength;

    public OmapVibe( FsoFramework.Subsystem subsystem, string sysfsnode )
    {
        this.subsystem = subsystem;
        this.sysfsnode = sysfsnode;

        this.direction = sysfsnode + "/direction";

        if ( !FsoFramework.FileHandling.isPresent( this.direction ) )
        {
            logger.error( @"sysfs class is damaged, missing $(this.direction); skipping." );
            return;
        }

        subsystem.registerObjectForService<FreeSmartphone.Device.Vibrator>( FsoFramework.Device.ServiceDBusName, FsoFramework.Device.VibratorServicePath, this );
        logger.info( "Created" );
    }

    public override string repr()
    {
        return @"<$sysfsnode>";
    }

    private int _valueToPercent( int value )
    {
        double max = max_strength;
        double v = value;
        return (int)(100.0 / max * v);
    }

    private uint _percentToValue( uint percent )
    {
        double p = percent;
        double max = max_strength;
        double value;
        if ( percent >= 100 )
            value = max_strength;
        else if ( percent <= 0 )
            value = 0;
        else
            value = p / 100.0 * max;
        return (int)value;
    }

    private void set_vibration( int strength )
    {
#if DEBUG
        message( "set vibration to %d", strength );
#endif
        FsoFramework.FileHandling.write( ( strength > 0 ) ? "1" : "0", this.direction );
        on = ( strength > 0 );
    }

    private bool onToggleTimeout()
    {
        if ( !on )
        {
            set_vibration( this.strength );
            smalltimeoutwatch = Timeout.add( don, onToggleTimeout );
        }
        else
        {
            set_vibration( 0 );
            if ( --pulses > 0 )
            {
                smalltimeoutwatch = Timeout.add( doff, onToggleTimeout );
            }
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
        pulses = 0;
    }

    //
    // FreeSmartphone.Device.Vibrator (DBUS API)
    //
    public async string get_name() throws DBusError, IOError
    {
        return Path.get_basename( sysfsnode );
    }

    public async void vibrate_pattern( int pulses, int delay_on, int delay_off, int strength ) throws FreeSmartphone.Error, DBusError, IOError
    {
        if ( this.pulses > 0 || fulltimeoutwatch > 0 )
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Already vibrating... please try again" );
        if ( pulses < 1 )
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Number of pulses needs to be at least 1" );
        if ( delay_on < 50 )
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Delay on duration needs to be at least 50 milliseconds" );
        if ( delay_off < 50 )
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Delay off duration needs to be at least 50 milliseconds" );

        this.don = delay_on;
        this.doff = delay_off;
        this.pulses = pulses;
        this.strength = strength;

        onToggleTimeout();
    }

    public async void vibrate( int milliseconds, int strength ) throws FreeSmartphone.Error, DBusError, IOError
    {

        if ( this.pulses > 0 || fulltimeoutwatch > 0 )
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Already vibrating... please try again" );
        if ( milliseconds < 50 )
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Vibration time needs to be at least 50 milliseconds" );

        cleanTimeouts();
        set_vibration( strength );
        fulltimeoutwatch = Timeout.add( milliseconds, () => {
            cleanTimeouts();
            set_vibration( 0 );
            return false;
        } );
    }

    public async void stop() throws FreeSmartphone.Error, DBusError, IOError
    {
        cleanTimeouts();
        set_vibration( 0 );
    }
}

} /* namespace */

static string sysfs_root;
Vibrator.OmapVibe instance;

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
    var dirname = GLib.Path.build_filename( sysfs_root, "bus", "platform", "devices", "omap_vibe" );
    if ( FsoFramework.FileHandling.isPresent( dirname ) )
    {
        instance = new Vibrator.OmapVibe( subsystem, dirname );
    }
    else
    {
        FsoFramework.theLogger.error( "No omap_vibe device found; vibrator object will not be available" );
    }
    return "fsodevice.vibrator_omapvibes";
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsodevice.vibrator_omapvibe fso_register_function()" );
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
