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

namespace Kernel26
{

/**
 * Implementation of org.freesmartphone.Device.PowerSupply for the Kernel26 Power-Class Device
 **/
class PowerSupply : FsoFramework.Device.PowerSupply, FsoFramework.AbstractObject
{
    FsoFramework.Subsystem subsystem;

    private string sysfsnode;
    private static uint counter;

    public PowerSupply( FsoFramework.Subsystem subsystem, string sysfsnode )
    {
        this.subsystem = subsystem;
        this.sysfsnode = sysfsnode;

        subsystem.registerServiceName( FsoFramework.Device.ServiceDBusName );
        subsystem.registerServiceObject( FsoFramework.Device.ServiceDBusName,
                                         "%s/%u".printf( FsoFramework.Device.PowerSupplyServicePath, counter++ ),
                                         this );

        logger.info( "created new PowerSupply object." );
    }

    public override string repr()
    {
        return "<FsoFramework.Device.PowerSupply @ %s>".printf( sysfsnode );
    }

    //
    // FsoFramework.Device.PowerSupply
    //
    public string GetName() throws DBus.Error
    {
        return Path.get_basename( sysfsnode );
    }

    public string GetPowerStatus() throws DBus.Error
    {
        return "unknown";
    }

    public int GetCapacity() throws DBus.Error
    {
        return 0;
    }
}

} /* namespace */

static string sysfs_root;
static string sys_class_powersupplies;
List<Kernel26.PowerSupply> instances;

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
    sysfs_root = config.stringValue( "cornucopia", "sysfs_root", "/sys" );
    sys_class_powersupplies = "%s/class/power_supply".printf( sysfs_root );

    // scan sysfs path for rtcs
    var dir = Dir.open( sys_class_powersupplies );
    var entry = dir.read_name();
    while ( entry != null )
    {
        var filename = Path.build_filename( sys_class_powersupplies, entry );
        instances.append( new Kernel26.PowerSupply( subsystem, filename ) );
        entry = dir.read_name();
    }
    return "fsodevice.kernel26_powersupply";
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    debug( "kernel26_powersupply fso_register_function()" );
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