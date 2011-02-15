/*
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
    public static const string POWERSUPPLY_MODULE_NAME = @"fsodevice.palmpre_quirks/powersupply";

    /**
     * @class TokenLib
     *
     * Helper class for reading tokens from the global configuration file /etc/tokens
     **/
    private class TokenLib
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

    /**
     * @class BatteryPowerSupply
     *
     * Management of the battery power supply on the Palm Pre devices
     **/
    private class BatteryPowerSupply :
        FreeSmartphone.Device.PowerSupply,
        FreeSmartphone.Info,
        FsoFramework.AbstractObject
    {
        private FsoFramework.Subsystem subsystem;
        private string master_node;
        private string slave_node;
        private int _current_capacity = -1;
        private int critical_capacity = -1;
        private FreeSmartphone.Device.PowerStatus _current_power_status = FreeSmartphone.Device.PowerStatus.UNKNOWN;
        private bool present;
        private bool _skip_authentication = false;

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

        public BatteryPowerSupply( FsoFramework.Subsystem subsystem )
        {
            this.subsystem = subsystem;

            _skip_authentication = FsoFramework.theConfig.boolValue( @"$(POWERSUPPLY_MODULE_NAME)/battery", "skip_authentication", false );

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

            // We now try to authenticate our battery but only if the user wants this
            bool authenticated = authenticateBattery();
            if (!_skip_authentication && !authenticated)
            {
                logger.error( "Battery authentication failed!" );
                return;
            }

            // Register our provided dbus service on the bus
            subsystem.registerObjectForService<FreeSmartphone.Device.PowerSupply>( FsoFramework.Device.ServiceDBusName, FsoFramework.Device.PowerSupplyServicePath, this );



            critical_capacity = FsoFramework.theConfig.intValue( @"$(POWERSUPPLY_MODULE_NAME)/battery", "critical", 10);
            current_capacity = getCapacity();

            var poll_timout = FsoFramework.theConfig.intValue( @"$(POWERSUPPLY_MODULE_NAME)/battery", "poll_timeout", 10);

            GLib.Timeout.add (poll_timout, ()=> {current_capacity = getCapacity(); return true;});

            logger.info( "Created new PowerSupply object." );
        }

        public override string repr()
        {
            return "<>";
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
        // FreeSmartphone.Info (DBUS API)
        //

        public async HashTable<string,Value?> get_info() throws DBusError, IOError
        {
            var res = new HashTable<string,Value?>( str_hash, str_equal );
            return res;
        }

        //
        // FreeSmartphone.Device.PowerStatus (DBUS API)
        //

        public async FreeSmartphone.Device.PowerStatus get_power_status() throws DBusError, IOError
        {
            return current_power_status;
        }

        public async int get_capacity() throws DBusError, IOError
        {
            return getCapacity();
        }
    }

    /**
     * @class PowerSupply
     **/
    public class PowerSupply : FsoFramework.AbstractObject
    {
        private BatteryPowerSupply battery_powersupply;

        public PowerSupply( FsoFramework.Subsystem subsystem )
        {
            /* Create all necessary sub-modules */
            if ( config.hasSection( @"$(POWERSUPPLY_MODULE_NAME)/battery" ) )
            {
                battery_powersupply = new BatteryPowerSupply( subsystem );
            }
        }

        public override string repr()
        {
            return "<PalmPre.PowerSupply @ >";
        }

    }

} /* namespace PalmPre */
