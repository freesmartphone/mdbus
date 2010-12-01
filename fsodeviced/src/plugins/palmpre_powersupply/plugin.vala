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

class TokenLib
{
    public static string tokenValue(string key, string def)
    {
        var tokens_file = "/etc/tokens";

        if (!FsoFramework.FileHandling.isPresent(tokens_file))
        {
            FsoFramework.theLogger.error("!!! File with necessary tokens is not found !!!");
            return def;
        }

        FsoFramework.SmartKeyFile tf = new FsoFramework.SmartKeyFile();
        if (tf.loadFromFile(tokens_file))
        {
            return tf.stringValue("tokens", key, def);
        }

        return def;
    }
}

public class BatteryPowerSupply : FreeSmartphone.Device.PowerSupply, FsoFramework.AbstractObject
{
    public static const string MODULE_NAME = "fsodevice.palmpre_powersupply";

    FsoFramework.Subsystem subsystem;
    private string master_node;
    private string slave_node;
    private int _current_capacity = -1;
    private int critical_capacity = -1;
    private FreeSmartphone.Device.PowerStatus _current_power_status = FreeSmartphone.Device.PowerStatus.UNKNOWN;
    internal bool present;

    //
    // Properties
    //

    private int current_capacity
    {
        get
        {
            return _current_capacity;
        }
        set
        {
            if ( _current_capacity != value )
            {
                updateCurrentPowerStatus(value);
                _current_capacity = value;
                capacity( value );
            }
        }
    }

    private void updateCurrentPowerStatus(int new_capacity)
    {
        if ( _current_capacity < new_capacity )
        {
            current_power_status = FreeSmartphone.Device.PowerStatus.CHARGING;
        }
        else if ( _current_capacity > new_capacity )
        {
            current_power_status = FreeSmartphone.Device.PowerStatus.DISCHARGING;
        }
        if ( new_capacity == 0 )
        {
            current_power_status = FreeSmartphone.Device.PowerStatus.EMPTY;
        }
        else if ( new_capacity < critical_capacity )
        {
            current_power_status = FreeSmartphone.Device.PowerStatus.CRITICAL;
        }
    }


    private FreeSmartphone.Device.PowerStatus current_power_status
    {
        get
        {
            return _current_power_status;
        }
        set
        {
            if(_current_power_status != value)
            {
                _current_power_status = value;
                power_status( value );
            }
        }
    }

    //
    // private methods
    //

    private bool authenticateBattery()
    {
        string battToCh = TokenLib.tokenValue("BATToCH", "");
        string battToResp = TokenLib.tokenValue("BATToRSP", "");

        logger.info(@"BATToCH = '$battToCh', BATToRSP = '$battToResp'");

        var mac_node = Path.build_filename(slave_node, "mac");
        FsoFramework.FileHandling.write(battToCh, mac_node);

        string response = FsoFramework.FileHandling.read(mac_node);
        if (response.down() != battToResp.down())
        {
            logger.error( @"Battery does not answer with the right response: $(response) (response) != $battToResp (expected response)" );
            return false;
        }

        return true;
    }

    //
    // public methods
    //

    public BatteryPowerSupply( FsoFramework.Subsystem subsystem)
    {
        this.subsystem = subsystem;

        master_node = "%s/devices/w1_bus_master1".printf(sysfs_root);

        var slave_count_path = Path.build_filename(master_node, "w1_master_slave_count");
        var slave_count = FsoFramework.FileHandling.read(slave_count_path);
        assert( logger.debug (@"Using $(slave_count_path) as slave count: '$(slave_count)'") );
        if (slave_count == "0")
        {
            present = false;
            logger.error("there is no battery available ... skipping");
            return;
        }

        var slave_name_path = Path.build_filename(master_node, "w1_master_slaves");
        var slave_name = FsoFramework.FileHandling.read(slave_name_path);
        assert( logger.debug (@"Using $(slave_name_path) as slave name: '$(slave_name)'") );
        slave_node = Path.build_filename(master_node, slave_name);

        logger.info(@"w1 slave '$(slave_node)' is our battery");

        // check if we only use a valid battery
        if (authenticateBattery())
            return;

        subsystem.registerServiceName(FsoFramework.Device.ServiceDBusName);
        subsystem.registerServiceObject(FsoFramework.Device.ServiceDBusName,
                                        "%s/%u".printf( FsoFramework.Device.PowerSupplyServicePath, 0),
                                        this);
        critical_capacity = FsoFramework.theConfig.intValue(MODULE_NAME, "critical", 10);
        current_capacity = getCapacity();

        var poll_timout = FsoFramework.theConfig.intValue(MODULE_NAME, "poll_timeout", 10);

        GLib.Timeout.add (poll_timout, ()=> {current_capacity = getCapacity(); return true;});

        logger.info( "created new PowerSupply object." );
    }



    public override string repr()
    {
        return "<FsoFramework.Device.PowerSupply @ >";
    }

    public bool isBattery()
    {
        return true;
    }

    public bool isPresent()
    {
        return true;
    }

    public int getCapacity()
    {
        if ( !isBattery() )
            return -1;
        if ( !isPresent() )
            return -1;

        return FsoFramework.FileHandling.read(Path.build_filename(slave_node, "getpercent")).to_int();
    }

    //
    // FreeSmartphone.Device.PowerStatus (DBUS API)
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

    public async FreeSmartphone.Device.PowerStatus get_power_status() throws DBus.Error
    {
        return current_power_status;
    }

    public async int get_capacity() throws DBus.Error
    {
        return getCapacity();
    }
}

} /* namespace */

internal static string sysfs_root;
internal static PalmPre.BatteryPowerSupply palmpre_battery;

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

    palmpre_battery = new PalmPre.BatteryPowerSupply( subsystem );

    return PalmPre.BatteryPowerSupply.MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsodevice.palmpre_powersupply fso_register_function()" );
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

