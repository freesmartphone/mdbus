/*
 * Copyright (C) 2011-2012 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

namespace N900
{
    public static const string MODULE_NAME = "fsodevice.n900_quirks";
}

internal AmbientLight.N900 ambientlight;
internal PowerSupply.N900 powersupply;
internal Proximity.N900 proximity;
internal Proximity.ProximityResource proximity_resource;
internal List<FsoDevice.BasePowerControlResource> resources;
internal List<FsoDevice.BasePowerControl> instances;

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    var config = FsoFramework.theConfig;
    var sysfs_root = config.stringValue( "cornucopia", "sysfs_root", "/sys" );

    if ( config.hasSection( @"$(N900.MODULE_NAME)/ambientlight" ) )
    {
        var dirname = GLib.Path.build_filename( sysfs_root, AmbientLight.DEFAULT_NODE );
        if ( FsoFramework.FileHandling.isPresent( dirname ) )
            ambientlight = new AmbientLight.N900( subsystem, dirname );
        else FsoFramework.theLogger.error( "No ambient light device found; ambient light object will not be available" );
    }

    if ( config.hasSection( @"$(N900.MODULE_NAME)/powercontrol" ) )
    {
        var hci_h4p = Path.build_filename( sysfs_root, "devices", "platform", "hci_h4p" );
        var wl12xx = Path.build_filename( sysfs_root, "devices", "platform", "wl12xx" );
        var bto = new N900.BluetoothPowerControl( subsystem, hci_h4p, wl12xx );
        instances.append( bto );
#if WANT_FSO_RESOURCE
        resources.append( new FsoDevice.BasePowerControlResource( bto, "Bluetooth", subsystem ) );
#endif
    }

    /*
    var wifio = new N900.WiFiPowerControl( subsystem, wl12xx );
    instances.append( wifio );
#if WANT_FSO_RESOURCE
    resources.append( new FsoDevice.BasePowerControlResource( wifio, "WiFi", subsystem ) );
#endif
    */

    if ( config.hasSection( @"$(N900.MODULE_NAME)/powersupply" ) )
    {
        var sys_devices_platform_msusb_hdrc = "%s/devices/platform/musb_hdrc".printf( sysfs_root );
        powersupply = new PowerSupply.N900( subsystem, sys_devices_platform_msusb_hdrc );
    }

    if ( config.hasSection( @"$(N900.MODULE_NAME)/proximity" ) )
    {
        var dirname = GLib.Path.build_filename( sysfs_root, "devices", "platform", "gpio-switch", "proximity" );
        if ( FsoFramework.FileHandling.isPresent( dirname ) )
        {
            proximity = new Proximity.N900( subsystem, dirname );
            proximity_resource = new Proximity.ProximityResource( subsystem, proximity );
        }
        else
        {
            FsoFramework.theLogger.error( "No proximity device found; proximity object will not be available" );
        }
    }
 
    return "fsodevice.n900_quirks";
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsodevice.n900_quirks fso_register_function()" );
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
