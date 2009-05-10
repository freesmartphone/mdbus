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

    // internal, so it can be accessable from aggregate power supply
    internal string name;
    internal string typ;
    internal string status = "unknown";
    internal bool present;

    public PowerSupply( FsoFramework.Subsystem subsystem, string sysfsnode )
    {
        this.subsystem = subsystem;
        this.sysfsnode = sysfsnode;
        this.name = Path.get_basename( sysfsnode );

        if ( !FsoFramework.FileHandling.isPresent( "%s/type".printf( sysfsnode ) ) )
        {
            logger.error( "^^^ sysfs class is damaged; skipping." );
            return;
        }

        this.typ = FsoFramework.FileHandling.read( "%s/type".printf( sysfsnode ) ).down();

        Idle.add( onIdle );

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

    public bool onIdle()
    {
        // trigger initial coldplug change notification
        FsoFramework.FileHandling.write( "change", "%s/uevent".printf( sysfsnode ) );
        return false; // mainloop: don't call again
    }

    public bool isBattery()
    {
        return typ == "battery";
    }

    public bool isPresent()
    {
        var node = isBattery() ? "%s/present" : "%s/online";
        var value = FsoFramework.FileHandling.read( node.printf( sysfsnode ) );
        return ( value != null && value.to_bool() );
    }

    public int getCapacity()
    {
        if ( !isBattery() )
            return -1;
        if ( !isPresent() )
            return -1;

        // try the capacity node first, this one is not supported by all power class devices
        var value = FsoFramework.FileHandling.read( "%s/capacity".printf( sysfsnode ) );
        if ( value != "" )
            return value.to_int();

        // fall back to energy_full and energy_now, this one seems to be present always
        var energy_full = FsoFramework.FileHandling.read( "%s/energy_full".printf( sysfsnode ) );
        var energy_now = FsoFramework.FileHandling.read( "%s/energy_now".printf( sysfsnode ) );
        if ( energy_full != "" && energy_now != "" )
            return (int) ( ( energy_now.to_double()  / energy_full.to_double() ) * 100.0 );

        return -1;
    }

    //
    // FsoFramework.Device.PowerSupply
    //
    public string GetName() throws DBus.Error
    {
        return name;
    }

    public string GetType() throws DBus.Error
    {
        return typ;
    }

    public string GetPowerStatus() throws DBus.Error
    {
        return status;
    }

    public int GetCapacity() throws DBus.Error
    {
        return getCapacity();
    }
}

/**
 * Implementation of org.freesmartphone.Device.PowerSupply as aggregated Kernel26 Power-Class Devices
 **/
class AggregatePowerSupply : FsoFramework.Device.PowerSupply, FsoFramework.AbstractObject
{
    private const uint POWER_SUPPLY_CAPACITY_CHECK_INTERVAL = 5 * 60;
    private const uint POWER_SUPPLY_CAPACITY_CRITICAL = 7;
    private const uint POWER_SUPPLY_CAPACITY_EMPTY = 3;

    private FsoFramework.Subsystem subsystem;
    private string sysfsnode;

    private string status = "unknown";
    private int capacity = -1;

    public AggregatePowerSupply( FsoFramework.Subsystem subsystem, string sysfsnode )
    {
        this.subsystem = subsystem;
        this.sysfsnode = sysfsnode;

        subsystem.registerServiceName( FsoFramework.Device.ServiceDBusName );
        subsystem.registerServiceObject( FsoFramework.Device.ServiceDBusName,
                                         FsoFramework.Device.PowerSupplyServicePath,
                                         this );

        FsoFramework.BaseKObjectNotifier.addMatch( "change", "power_supply", onPowerSupplyChangeNotification );

        Idle.add( onIdle );

        logger.info( "created new AggregatePowerSupply object." );
    }

    public override string repr()
    {
        return "<FsoFramework.Device.AggregatePowerSupply @ %s>".printf( sysfsnode );
    }

    public bool onIdle()
    {
        onTimeout();
        Timeout.add_seconds( POWER_SUPPLY_CAPACITY_CHECK_INTERVAL, onTimeout );
        return false;
    }

    public bool onTimeout()
    {
        var capacity = getCapacity();
        sendCapacityIfChanged( capacity );
        if ( status == "discharging" )
        {
            if ( capacity <= POWER_SUPPLY_CAPACITY_EMPTY )
            {
                sendStatusIfChanged( "empty" );
            }
            else if ( capacity <= POWER_SUPPLY_CAPACITY_CRITICAL )
            {
                sendStatusIfChanged( "critical" );
            }
        }
        return true;
    }

    public void onPowerSupplyChangeNotification( HashTable<string,string> properties )
    {
        var name = properties.lookup( "POWER_SUPPLY_NAME" );
        assert( name != null );
        var typ = properties.lookup( "POWER_SUPPLY_TYPE" ).down();
        assert( typ != null );

        var status = "unknown";
        var present = false;

        if ( typ != "battery" )
        {
            present = properties.lookup( "POWER_SUPPLY_ONLINE" ).to_bool();
            status = present ? "online" : "offline";
        }
        else
        {
            status = properties.lookup( "POWER_SUPPLY_STATUS" ).down();
            present = properties.lookup( "POWER_SUPPLY_PRESENT" ).to_bool();

            if ( status == "not charging" )
            {
                status = present ? "error" : "removed";
            }
        }

        assert( status != null );

        logger.info( "got power status change notification for %s: %s".printf( name, status ) );

        // set status in instance
        foreach ( var supply in instances )
        {
            if ( supply.name == name )
            {
                supply.status = status;
                supply.present = present;
                break;
            }
        }

        computeNewStatus();
    }

    public void computeNewStatus()
    {
        var statusForAll = true;
        PowerSupply battery = null;
        PowerSupply charger = null;

        // first, check whether we have enough information to compute the status at all
        foreach ( var supply in instances )
        {
            logger.debug( "supply %s status = %s".printf( supply.name, supply.status ) );
            logger.debug( "supply %s type = %s".printf( supply.name, supply.typ ) );

            if ( supply.status == "unknown" )
                statusForAll = false;

            if ( supply.typ == "battery" ) // FIXME: revisit to handle multiple batteries
            {
                battery = supply;
            }
            else
            {
                if ( supply.status == "online" ) // FIXME: revisit to handle multiple chargers
                    charger = supply;
            }
        }

        if ( !statusForAll )
        {
            logger.debug( "^^^ not enough information present to compute overall status" );
            return;
        }

        // if we have a battery and it is inserted, this is our aggregate status
        if ( battery != null && battery.status != "removed" )
        {
            sendStatusIfChanged( battery.status );
        }
        // if we don't have a battery, return the name of the power supply providing power
        else
        {
            sendStatusIfChanged( charger.name );
        }
    }

    public void sendStatusIfChanged( string status )
    {
        logger.debug( "sendStatusIfChanged old %s new %s".printf( this.status, status ) );

        // some power supply classes (Thinkpad) have a bug where after
        // 'discharging' you shortly get a 'full' before 'charging'
        // when you insert the AC plug.
        if ( ( this.status == "discharging" ) && ( status == "full" ) )
        {
            logger.warning( "BUG: power supply class sent 'full' after 'discharging'" );
            return;
        }

        if ( this.status == status )
            return;

        this.status = status;
        PowerStatus( status );
    }

    public void sendCapacityIfChanged( int capacity )
    {
        if ( this.capacity == capacity )
        return;

        this.capacity = capacity;
        Capacity( capacity );
    }

    public int getCapacity()
    {
        var amount = -1;
        var numValues = 0;
        // walk through all power nodes and compute arithmetic mean
        foreach( var supply in instances )
        {
            var v = supply.getCapacity();
            if ( v != -1 )
            {
                amount += v;
                numValues++;
            }
        }
        return amount / numValues;
    }

    //
    // FsoFramework.Device.PowerSupply
    //
    public string GetName() throws DBus.Error
    {
        return Path.get_basename( sysfsnode );
    }

    public string GetType() throws DBus.Error
    {
        return "aggregate";
    }

    public string GetPowerStatus() throws DBus.Error
    {
        // walk through all power nodes and get
        return "unknown";
    }

    public int GetCapacity() throws DBus.Error
    {
        return getCapacity();
    }
}

} /* namespace */

internal static string sysfs_root;
internal static string sys_class_powersupplies;
internal List<Kernel26.PowerSupply> instances;
internal Kernel26.AggregatePowerSupply aggregate;

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

    // always create aggregated object
    aggregate = new Kernel26.AggregatePowerSupply( subsystem, sys_class_powersupplies );

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