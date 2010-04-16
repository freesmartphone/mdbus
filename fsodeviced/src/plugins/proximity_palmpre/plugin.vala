/*
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

namespace Proximity
{

class PalmPre : FreeSmartphone.Device.Proximity, FsoFramework.AbstractObject
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

    public PalmPre( FsoFramework.Subsystem subsystem, string sysfsnode )
    {
        this.subsystem = subsystem;
        this.sysfsnode = sysfsnode;

        this.direction = sysfsnode + "/direction";

        if ( !FsoFramework.FileHandling.isPresent( this.direction ) )
        {
            logger.error( @"sysfs class is damaged, missing $(this.direction); skipping." );
            return;
        }

        subsystem.registerServiceName( FsoFramework.Device.ServiceDBusName );
        subsystem.registerServiceObjectWithPrefix(
            FsoFramework.Device.ServiceDBusName,
            FsoFramework.Device.ProximityServicePath,
            this );
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

    //
    // FreeSmartphone.Device.Proximity (DBUS API)
    //
    public async void get_proximity( out int proximity, out int timestamp ) throws FreeSmartphone.Error, DBus.Error
    {
        proximity = -1;
        timestamp = 0;
    }
}

} /* namespace */

static string sysfs_root;
Proximity.PalmPre instance;

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
    var dirname = GLib.Path.build_filename( sysfs_root, "class", "input", "input3" );
    if ( FsoFramework.FileHandling.isPresent( dirname ) )
    {
        instance = new Proximity.PalmPre( subsystem, dirname );
    }
    else
    {
        FsoFramework.theLogger.error( "No proximity device found; proximity object will not be available" );
    }
    return "fsodevice.proximity_palmpre";
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsodevice.proximity_palmpre fso_register_function()" );
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
