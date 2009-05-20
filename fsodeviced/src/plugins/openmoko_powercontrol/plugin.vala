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

namespace Openmoko
{

/**
 * Bluetooth power control
 **/
class BluetoothPowerControl : FsoDevice.BasePowerControl
{
    FsoFramework.Subsystem subsystem;

    private string sysfsnode;
    private static uint counter;

    // internal, so it can be accessable from aggregate input device
    internal string name;
    internal string product = "<Unknown Product>";
    internal int fd = -1;

    public BluetoothPowerControl( FsoFramework.Subsystem subsystem, string sysfsnode )
    {
        this.subsystem = subsystem;
        this.sysfsnode = sysfsnode;
        this.name = Path.get_basename( sysfsnode );

        subsystem.registerServiceName( FsoFramework.Device.ServiceDBusName );
        subsystem.registerServiceObject( FsoFramework.Device.ServiceDBusName,
                                         "%s/%u".printf( FsoFramework.Device.InputServicePath, counter++ ),
                                         this );

        base( Path.build_filename( sysfsnode, "power_on" ) );

        logger.info( "created new PowerControl object." );
    }
}

} /* namespace */

internal List<FsoDevice.BasePowerControl> instances;

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    // grab sysfs paths
    var config = FsoFramework.theMasterKeyFile();
    var sysfs_root = config.stringValue( "cornucopia", "sysfs_root", "/sys" );
    var devices = Path.build_filename( sysfs_root, "bus", "platform", "devices" );

    var bluetooth = Path.build_filename( devices, "neo1973-pm-bt.0" );

    if ( FsoFramework.FileHandling.isPresent( bluetooth ) )
    {
        instances.append( new Openmoko.BluetoothPowerControl( subsystem, bluetooth ) );
    }

    //TODO: add other devices

    return "fsodevice.openmoko_powercontrol";
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    debug( "input fso_register_function()" );
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