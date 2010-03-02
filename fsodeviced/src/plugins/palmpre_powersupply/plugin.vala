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

        if (!FsoFramework.FileHandling.isPresent(tokens_file)) {
            logger.error("!!! File with necessary tokens is not found !!!");
            return "";
        }

        FsoFramework.SmartKeyFile tf = 
            new FsoFramework.SmartKeyFile(tokens_file);
        return tf.stringValue("tokens", key, def);
    }
}

class BatteryPowerSupply : FreeSmartphone.Device.PowerSupply, FsoFramework.AbstractObject
{
    FsoFramework.Subsystem subsystem;
    private string master_node;
    private string slave_node;

    internal string name;
    internal string typ;
    internal FreeSmartphone.Device.PowerStatus status = FreeSmartphone.Device.PowerStatus.UNKNOWN;
    internal bool present;

    public BatteryPowerSupply( FsoFramework.Subsystem subsystem)
    {
        this.subsystem = subsystem;

        master_node = "%s/devices/w1_bus_master".printf(sysfs_root);

        var slave_count =
            FsoFramework.FileHandling.read("%s/w1_master_slave_count".printf(master_node));
        if (slave_count == "0") {
            present == false;
            logger.error("there is no battery available ... skipping");
            return;
        }

        var slave_name =
            FsoFramework.FileHandling.read("%s/w1_master_slaves".printf(master_node));
        slave_node = "%s/%s".printf(master_node, slave_node);

        logger.info(@"w1 slave '$(slave_node)' is our battery");

        /* check that we only use a valid battery */
        if (authenticateBattery())
            return;
        
        subsystem.registerServiceName(FsoFramework.Device.ServiceDBusName);
        subsystem.registerServiceObject(FsoFramework.Device.ServiceDBusName,
                                        "%s/%u".printf( FsoFramework.Device.PowerSupplyServicePath, 0),
                                        this);

        logger.info( "created new PowerSupply object." );
    }

    private bool authenticateBattery()
    {
        string battToCh = TokenLib.tokenValue("BATToCH", "");
        string battToResp = TokenLib.tokenValue("BATToRSP", "");

        logger.info(@"BATToCH = '@battToCh', BATToRSP = '@battToResp'");

        var mac_node = @"$(slave_node)/mac";
        FsoFramework.FileHandling.write(battToCh, mac_node);
        
        string response = FsoFramework.FileHandling.read(mac_node);
        if (response != battToResp) {
            logger.error("battery does not answer with the right response!");
            return false;
        }

        return true;
    }

    public override string repr()
    {
        return "<FsoFramework.Device.PowerSupply @ %s>".printf( sysfsnode );
    }

    public bool isBattery()
    {
        return true;
    }

    public bool isPresent()
    {
        return 0;
    }

    public int getCapacity()
    {
        if ( !isBattery() )
            return -1;
        if ( !isPresent() )
            return -1;

        /* FIXME should we use the 'getpercent' sysfs node ? */

        return -1;
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
        return status;
    }

    public async int get_capacity() throws DBus.Error
    {
        return getCapacity();
    }
}

} /* namespace */

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

    instances.append( new PalmPre.BatteryPowerSupply( subsystem, filename ) );

    return "fsodevice.palmpre_powersupply";
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
