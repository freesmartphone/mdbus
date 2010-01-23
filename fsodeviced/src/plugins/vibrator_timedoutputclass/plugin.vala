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

class TimedOutputClass : FreeSmartphone.Device.Vibrator, FsoFramework.AbstractObject
{
    FsoFramework.Subsystem subsystem;

    private int max_enable;
    private string sysfsnode;
    private string enable;

    private uint fulltimeoutwatch;
    private uint smalltimeoutwatch;
    private uint don;
    private uint doff;
    private bool on;

    private uint pulses;


    public TimedOutputClass( FsoFramework.Subsystem subsystem, string sysfsnode )
    {
        this.subsystem = subsystem;
        this.sysfsnode = sysfsnode;

        this.enable = sysfsnode + "/enable";

        if ( !FsoFramework.FileHandling.isPresent( this.enable ) )
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

    private void set_enable( int duration_ms )
    {
        if ( duration_ms < 0 )
        {
            duration_ms = 0;
        }
        debug( "set_enable: %d", duration_ms );
        FsoFramework.FileHandling.write( duration_ms.to_string(), this.enable );
        on = ( duration_ms > 0 );
    }

    private bool onToggleTimeout()
    {
        message( "on = %d, pulses = %d", (int)on, (int)pulses );
        if ( !on )
        {
            set_enable( (int)don );
            smalltimeoutwatch = Timeout.add( don, onToggleTimeout );
        }
        else
        {
            if ( --pulses > 0 )
            {
                on = false;
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
        on = false;
    }

    //
    // FreeSmartphone.Device.Vibrator (DBUS API)
    //
    public async string get_name() throws DBus.Error
    {
        return Path.get_basename( sysfsnode );
    }

    public async void vibrate_pattern( int pulses, int delay_on, int delay_off, int strength ) throws FreeSmartphone.Error, DBus.Error
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

        onToggleTimeout();
    }

    public async void vibrate( int milliseconds, int strength ) throws FreeSmartphone.Error, DBus.Error
    {
        if ( pulses > 0 || fulltimeoutwatch > 0 )
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Already vibrating... please try again" );
        if ( milliseconds < 50 )
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Vibration timeout needs to be at least 50 milliseconds" );

        cleanTimeouts();
        set_enable( milliseconds );
        fulltimeoutwatch = Timeout.add( milliseconds, () => {
            cleanTimeouts();
            return false;
        } );
    }

    public async void stop() throws FreeSmartphone.Error, DBus.Error
    {
        cleanTimeouts();
        set_enable( 0 );
    }
}

} /* namespace */

static string sysfs_root;
static string sys_class_net;
static string sys_class_timedoutputs;
List<Vibrator.TimedOutputClass> instances;

/**
 * This function gets caltimedoutput on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    // grab sysfs paths
    var config = FsoFramework.theConfig;
    sysfs_root = config.stringValue( "cornucopia", "sysfs_root", "/sys" );
    sys_class_timedoutputs = "%s/class/timed_output".printf( sysfs_root );
    sys_class_net = "%s/class/net".printf( sysfs_root );

    // scan sysfs path for timedoutputs
    var dir = Dir.open( sys_class_timedoutputs );
    var entry = dir.read_name();
    while ( entry != null )
    {
        if ( "vib" in entry )
        {
            var filename = Path.build_filename( sys_class_timedoutputs, entry );
            instances.append( new Vibrator.TimedOutputClass( subsystem, filename ) );
        }
        entry = dir.read_name();
    }
    return "fsodevice.vibrator_timedoutputclasss";
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsodevice.vibrator_timedoutputclasss fso_register_function()" );
}

/**
 * This function gets caltimedoutput on plugin load time.
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
