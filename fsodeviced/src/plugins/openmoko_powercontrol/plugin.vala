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

namespace Openmoko
{
    public static const string CONFIG_SECTION = "fsodevice.openmoko_powercontrol";

/**
 * Common device power control for Openmoko GTA01 and Openmoko GTA02
 **/
class DevicePowerControl : FsoDevice.BasePowerControl
{

    private FsoFramework.Subsystem subsystem;
    private string sysfsnode;
    private string name;

    public DevicePowerControl( FsoFramework.Subsystem subsystem, string sysfsnode )
    {
        base( Path.build_filename( sysfsnode, "power_on" ) );
        this.subsystem = subsystem;
        this.sysfsnode = sysfsnode;
        this.name = Path.get_basename( sysfsnode );

        subsystem.registerObjectForServiceWithPrefix<FreeSmartphone.Device.PowerControl>( FsoFramework.Device.ServiceDBusName, FsoFramework.Device.PowerControlServicePath, this );

        logger.info( "created." );
    }
}

/**
 * UsbHost mode control for Openmoko GTA02
 **/
class UsbHostModeControl : FsoDevice.BasePowerControl
{
    private FsoFramework.Subsystem subsystem;
    private string sysfsnode;
    private string umodenode;
    private string name;

    public UsbHostModeControl( FsoFramework.Subsystem subsystem, string sysfsnode )
    {
        base( Path.build_filename( sysfsnode, "power_on" ) );
        this.subsystem = subsystem;
        this.sysfsnode = sysfsnode;
        this.umodenode = Path.build_filename( sysfs_root, "devices", "platform", "s3c2410-ohci", "usb_mode" );
        this.name = Path.get_basename( sysfsnode );

        subsystem.registerObjectForServiceWithPrefix<FreeSmartphone.Device.PowerControl>( FsoFramework.Device.ServiceDBusName, FsoFramework.Device.PowerControlServicePath, this );

        logger.info( "created." );
    }

    public override void setPower( bool on )
    {
        // first, set/clear 5v via USB
        base.setPower( on );
        // then, set/clear logical mode
        var logical = on ? "host" : "device";
        FsoFramework.FileHandling.write( logical, umodenode );
    }
}

/**
 * WiFi power control for Openmoko GTA02
 **/
class WiFiPowerControl : FsoDevice.BasePowerControl
{
    private FsoFramework.Subsystem subsystem;
    private string sysfsnode;
    private string name;

    public WiFiPowerControl( FsoFramework.Subsystem subsystem, string sysfsnode )
    {
        base( Path.build_filename( sysfsnode, null ) );
        this.subsystem = subsystem;
        this.sysfsnode = sysfsnode;
        this.name = Path.get_basename( sysfsnode );

        subsystem.registerObjectForServiceWithPrefix<FreeSmartphone.Device.PowerControl>( FsoFramework.Device.ServiceDBusName, FsoFramework.Device.PowerControlServicePath, this );

        logger.info( "created." );
    }

    public override bool getPower()
    {
        // WiFi is always eth0 on GTA02
        return FsoFramework.FileHandling.isPresent( Path.build_filename( sysfs_root, "class", "net", "eth0" ) );
    }

    public override void setPower( bool on )
    {
        var powernode = on ? "bind" : "unbind";
        FsoFramework.FileHandling.write( "s3c2440-sdi", Path.build_filename( sysfsnode, powernode ) );
    }
}

} /* namespace */

internal List<FsoDevice.BasePowerControlResource> resources;
internal List<FsoDevice.BasePowerControl> instances;
internal static string sysfs_root;

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
    var devices = Path.build_filename( sysfs_root, "bus", "platform", "devices" );
    var drivers = Path.build_filename( sysfs_root, "bus", "platform", "drivers" );

    var ignore_bluetooth = config.boolValue( Openmoko.CONFIG_SECTION, "ignore_bluetooth", false );
    var ignore_gps = config.boolValue( Openmoko.CONFIG_SECTION, "ignore_gps", false );
    var ignore_wifi = config.boolValue( Openmoko.CONFIG_SECTION, "ignore_wifi", false );
    var ignore_usbhost = config.boolValue( Openmoko.CONFIG_SECTION, "ignore_usbhost", false );

    if ( !ignore_bluetooth )
    {
        var bluetooth = Path.build_filename( devices, "gta02-pm-bt.0" );
        if ( FsoFramework.FileHandling.isPresent( bluetooth ) )
        {
            var o = new Openmoko.DevicePowerControl( subsystem, bluetooth );
            instances.append( o );
    #if WANT_FSO_RESOURCE
            resources.append( new FsoDevice.BasePowerControlResource( o, "Bluetooth", subsystem ) );
    #endif
        }
    }

    if ( !ignore_gps )
    {
        var gps = Path.build_filename( devices, "gta02-pm-gps.0" );
        if ( FsoFramework.FileHandling.isPresent( gps ) )
        {
            var o = new Openmoko.DevicePowerControl( subsystem, gps );
            instances.append( o );
    #if WANT_FSO_RESOURCE
            resources.append( new FsoDevice.BasePowerControlResource( o, "GPS", subsystem ) );
    #endif
        }
    }


    if ( !ignore_usbhost )
    {
        var usbhost = Path.build_filename( devices, "gta02-pm-usbhost.0" );
        if ( FsoFramework.FileHandling.isPresent( usbhost ) )
        {
            var o = new Openmoko.UsbHostModeControl( subsystem, usbhost );
            instances.append( o );
    #if WANT_FSO_RESOURCE
            resources.append( new FsoDevice.BasePowerControlResource( o, "UsbHost", subsystem ) );
    #endif
        }
    }

    if ( !ignore_wifi )
    {
        var wifi = Path.build_filename( drivers, "s3c2440-sdi" );
        if ( FsoFramework.FileHandling.isPresent( wifi ) )
        {
            var o = new Openmoko.WiFiPowerControl( subsystem, wifi );
            instances.append( o );
    #if WANT_FSO_RESOURCE
            resources.append( new FsoDevice.BasePowerControlResource( o, "WiFi", subsystem ) );
    #endif
        }
    }

    //TODO: add other devices

    return Openmoko.CONFIG_SECTION;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsodevice.openmoko_powercontrol fso_register_function()" );
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
