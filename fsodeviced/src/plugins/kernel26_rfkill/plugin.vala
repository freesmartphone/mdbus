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
 * @class Kernel26.RfKillPowerControl
 *
 * Implementing org.freesmartphone.Device.PowerControl via Linux 2.6 rfkill API
 **/
class RfKillPowerControl : FreeSmartphone.Device.PowerControl, FsoFramework.AbstractObject
{
    private FsoFramework.Subsystem subsystem;
    private string sysfsnode;
    private string name;
    protected static uint counter;

    public RfKillPowerControl( FsoFramework.Subsystem subsystem, string sysfsnode )
    {
        this.subsystem = subsystem;
        this.sysfsnode = sysfsnode;
        this.name = Path.get_basename( sysfsnode );


        subsystem.registerServiceName( FsoFramework.Device.ServiceDBusName );
        subsystem.registerServiceObject( FsoFramework.Device.ServiceDBusName,
                                         "%s/%u".printf( FsoFramework.Device.PowerControlServicePath, counter++ ),
                                         this );


        logger.info( "created." );
    }

    public override string repr()
    {
        return @"<$name>";
    }

    public bool getPower()
    {
        return false;
    }

    public void setPower( bool on )
    {
    }

    //
    // DBUS API (org.freesmartphone.Device.PowerControl)
    //
    public async bool get_power() throws DBus.Error
    {
        return getPower();
    }

    public async void set_power( bool on ) throws DBus.Error
    {
        setPower( on );
    }
}

} /* namespace */

internal List<Kernel26.RfKillPowerControl> instances;
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
    var config = FsoFramework.theMasterKeyFile();
    sysfs_root = config.stringValue( "cornucopia", "sysfs_root", "/sys" );
    var rfkill = Path.build_filename( sysfs_root, "class", "rfkill" );

    // scan sysfs path for rfkill devices
    var dir = Dir.open( rfkill );
    var entry = dir.read_name();
    while ( entry != null )
    {
        var filename = Path.build_filename( rfkill, entry );
        instances.append( new Kernel26.RfKillPowerControl( subsystem, filename ) );
        entry = dir.read_name();
    }
    return "fsodevice.kernel26_rfkill";
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    debug( "fsodevice.kernel26_rfkill fso_register_function()" );
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
