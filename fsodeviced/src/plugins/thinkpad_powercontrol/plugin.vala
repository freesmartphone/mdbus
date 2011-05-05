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

namespace Thinkpad
{

/**
 * Bluetooth power control for IBM Thinkpad ACPI
 **/
class BluetoothPowerControl : FsoDevice.BasePowerControl
{
    private FsoFramework.Subsystem subsystem;
    private string sysfsnode;
    private string name;

    public BluetoothPowerControl( FsoFramework.Subsystem subsystem, string sysfsnode )
    {
        base( sysfsnode );
        this.subsystem = subsystem;
        this.sysfsnode = sysfsnode;
        this.name = Path.get_basename( sysfsnode );

        subsystem.registerObjectForServiceWithPrefix<FreeSmartphone.Device.PowerControl>( FsoFramework.Device.ServiceDBusName, FsoFramework.Device.PowerControlServicePath, this );

        logger.info( "created." );
    }
}

} /* namespace */

internal List<FsoDevice.BasePowerControl> instances;
internal static string procfs_root;

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
    procfs_root = config.stringValue( "cornucopia", "procfs_root", "/proc" );

    var bluetooth = Path.build_filename( procfs_root, "bluetooth" );
    if ( FsoFramework.FileHandling.isPresent( bluetooth ) )
    {
        instances.append( new Thinkpad.BluetoothPowerControl( subsystem, bluetooth ) );
    }

    //TODO: add other devices

    return "fsodevice.thinkpad_powercontrol";
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsodevice.thinkpad_powercontrol fso_register_function()" );
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
