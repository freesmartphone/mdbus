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

namespace PowerSupply
{

/**
 * Implementation of org.freesmartphone.Device.PowerSupply for the Nokia N900 device
 **/
class N900 : FreeSmartphone.Device.PowerSupply,
             FreeSmartphone.Info,
             FsoFramework.AbstractObject
{
    FsoFramework.Subsystem subsystem;

    private string sysfsnode;

    // internal (accessible for aggregate power supply)
    internal string name;
    internal string typ;
    internal FreeSmartphone.Device.PowerStatus status = FreeSmartphone.Device.PowerStatus.UNKNOWN;
    internal bool present;

    public N900( FsoFramework.Subsystem subsystem )
    {
        this.subsystem = subsystem;

        Idle.add( onIdle );

        subsystem.registerServiceName( FsoFramework.Device.ServiceDBusName );
        subsystem.registerServiceObjectWithPrefix( FsoFramework.Device.ServiceDBusName, FsoFramework.Device.PowerSupplyServicePath, this );

        logger.info( "Created" );
    }

    public override string repr()
    {
        return @"<$sysfsnode>";
    }

    public bool onIdle()
    {
        /*
        // trigger initial coldplug change notification, if we are on a real sysfs
        if ( sysfsnode.has_prefix( "/sys" ) )
        {
            assert( logger.debug( "Triggering initial coldplug change notification" ) );
            FsoFramework.FileHandling.write( "change", "%s/uevent".printf( sysfsnode ) );
        }
        else
        {
            assert( logger.debug( "Synthesizing initial coldplug change notification" ) );
            var uevent = FsoFramework.FileHandling.read( "%s/uevent".printf( sysfsnode ) );
            var parts = uevent.split( "\n" );
            var properties = new HashTable<string, string>( str_hash, str_equal );
            foreach ( var part in parts )
            {
#if DEBUG
                message( "%s", part );
#endif
                var elements = part.split( "=" );
                if ( elements.length == 2 )
                {
                    properties.insert( elements[0], elements[1] );
                }
            }
            aggregate.onPowerSupplyChangeNotification( properties );
        }
        */
        return false; // mainloop: don't call again
    }

    public bool isBattery()
    {
        return typ == "battery";
    }

    public bool isPresent()
    {
        /*
        var node = isBattery() ? "%s/present" : "%s/online";
        var value = FsoFramework.FileHandling.read( node.printf( sysfsnode ) );
        return ( value != null && value == "1" );
        */
        return true;
    }

    public int getCapacity()
    {
        /*
        if ( !isBattery() )
            return -1;
        if ( !isPresent() )
            return -1;

        // try the capacity node first, this one is not supported by all power class devices
        var value = FsoFramework.FileHandling.readIfPresent( "%s/capacity".printf( sysfsnode ) );
        if ( value != "" )
            return value.to_int();

#if DEBUG
        message( "capacity node not available, using energy_full and energy_now" );
#endif

        // fall back to energy_full and energy_now
        var energy_full = FsoFramework.FileHandling.read( "%s/energy_full".printf( sysfsnode ) );
        var energy_now = FsoFramework.FileHandling.read( "%s/energy_now".printf( sysfsnode ) );
        if ( energy_full != "" && energy_now != "" )
            return (int) ( ( energy_now.to_double()  / energy_full.to_double() ) * 100.0 );
        */
        return -1;
    }

    //
    // FreeSmartphone.Info (DBUS API)
    //
    public async HashTable<string,Value?> get_info() throws DBus.Error
    {
        var res = new HashTable<string,Value?>( str_hash, str_equal );
        /*
        res.insert( "name", name );

        var dir = Dir.open( sysfsnode );
        var entry = dir.read_name();
        while ( entry != null )
        {
            if ( entry != "uevent" )
            {
                var filename = Path.build_filename( sysfsnode, entry );
                var contents = FsoFramework.FileHandling.read( filename );
                if ( contents != "" )
                {
                    res.insert( entry, contents );
                }
            }
            entry = dir.read_name();
        }
        */
        return res;
    }

    //
    // FreeSmartphone.Device.PowerStatus (DBUS API)
    //
    public async FreeSmartphone.Device.PowerStatus get_power_status() throws DBus.Error
    {
        return status;
    }

    public async int get_capacity() throws DBus.Error
    {
        return getCapacity();
    }
}

} /* namespace */

internal static string sysfs_root;
internal static string sys_class_powersupplies;
internal PowerSupply.N900 instance;

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
    sys_class_powersupplies = "%s/class/power_supply".printf( sysfs_root );

    instance = new PowerSupply.N900( subsystem );

    return "fsodevice.powersupply_n900";
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsodevice.powersupply_n900 fso_register_function()" );
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
