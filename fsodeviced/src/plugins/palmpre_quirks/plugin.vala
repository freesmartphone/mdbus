/**
 * Copyright (C) 2010 Simon Busch <morphis@gravedo.de>
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

namespace PalmPre
{
    public const string MODULE_NAME = "palmpre_quirks";
    public string sysfs_root;
}

internal static PalmPre.TouchscreenManager touchscreen_manager;
internal static PalmPre.PowerSupply power_supply;

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    var config = FsoFramework.theConfig;

    PalmPre.sysfs_root = config.stringValue( "cornucopia", "sysfs_root", "/sys" );


    /* Initialize all different parts of this module but only when the config requires them */
    if ( config.hasSection( @"$(PalmPre.MODULE_NAME).touchscreen") )
    {
        touchscreen_manager = new PalmPre.TouchscreenManager( subsystem );
    }

    if ( config.hasSection( @"$(PalmPre.MODULE_NAME).powersupply") )
    {
        power_supply = new PalmPre.PowerSupply( subsystem );
    }

    return PalmPre.MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsodevice.palmpre_quirks fso_register_function()" );
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

