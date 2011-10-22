/*
 * Copyright (C) 2011 Klaus 'mrmoku' Kurzmann <mok@fluxnetz.de>
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

namespace GTA04
{
    public static const string CONFIG_SECTION = "fsodevice.gta04_powercontrol";

/**
 * Common device power control for Openmoko GTA04
 **/
class GpsPowerControl : FsoDevice.BasePowerControl
{

    private FsoFramework.Subsystem subsystem;
    private string sysfsnode;
    private string name;

    public GpsPowerControl( FsoFramework.Subsystem subsystem, string sysfsnode )
    {
        base( Path.build_filename( sysfsnode, "value" ) );
        this.subsystem = subsystem;
        this.sysfsnode = sysfsnode;
        this.name = Path.get_basename( sysfsnode );

        subsystem.registerObjectForServiceWithPrefix<FreeSmartphone.Device.PowerControl>( FsoFramework.Device.ServiceDBusName, FsoFramework.Device.PowerControlServicePath, this );

        logger.info( "created." );
    }

    public override void setPower( bool on )
    {
        if ( on )
        {
            // on - off - on to properly reset the GPS
            base.setPower( true );
            Posix.usleep( 200 );
            base.setPower( false );
            Posix.usleep( 200 );
            base.setPower( true );
        }
        else
        {
            base.setPower( false );
        }
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
    var gpio = Path.build_filename( sysfs_root, "class", "gpio" );

    var gps_gpio = Path.build_filename( gpio, "gpio145" );
    if ( FsoFramework.FileHandling.isPresent( gps_gpio ) )
    {
        var o = new GTA04.GpsPowerControl( subsystem, gps_gpio );
        instances.append( o );
#if WANT_FSO_RESOURCE
        resources.append( new FsoDevice.BasePowerControlResource( o, "GPS", subsystem ) );
#endif
    }

    return GTA04.CONFIG_SECTION;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsodevice.gta04_powercontrol fso_register_function()" );
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
