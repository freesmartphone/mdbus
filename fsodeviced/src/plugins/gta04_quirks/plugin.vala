/*
 * Copyright (C) 2010-2012 Simon Busch <morphis@gravedo.de>
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

namespace Gta04
{
    public static const string MODULE_NAME = "fsodevice.gta04_quirks";
}

internal List<FsoDevice.BasePowerControlResource> resources;
internal List<FsoDevice.BasePowerControl> instances;

internal Gta04.Info info;

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

    if ( config.hasSection( @"$(Gta04.MODULE_NAME)/powercontrol" ) )
    {
        var gpio = Path.build_filename( sysfs_root, "class", "gpio" );
        var gps_gpio = Path.build_filename( gpio, "gpio145" );
        if ( FsoFramework.FileHandling.isPresent( gps_gpio ) )
        {
            var o = new Gta04.GpsPowerControl( subsystem, gps_gpio );
            instances.append( o );
#if WANT_FSO_RESOURCE
            resources.append( new FsoDevice.BasePowerControlResource( o, "GPS", subsystem ) );
#endif
        }
    }

    if ( config.hasSection( @"$(Gta04.MODULE_NAME)/info" ) )
    {
        var info = new Gta04.Info( subsystem );
    }

    return Gta04.MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( @"$(Gta04.MODULE_NAME) fso_register_function()" );
}

// vim:ts=4:sw=4:expandtab
