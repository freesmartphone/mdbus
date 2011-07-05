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

    internal class UsbGadgetListener : FsoFramework.AbstractObject
    {
        public enum PowerSource
        {
            NONE,
            BUS,
            CHARGER
        }

        public bool host_connected { get; private set; }
        public PowerSource power_source { get; private set; }
        public uint power_current_ma { get; private set; }

        public signal void powerStatusChanged();
        public signal void hostStatusChanged();

        construct
        {
            FsoFramework.BaseKObjectNotifier.addMatch( "change", "platform", onPlatformChangeEvent );
        }

        public void initialize()
        {
            var powersource_node = "%s/devices/platform/usb_gadget/source".printf(sysfs_root);
            parsePowerSource( FsoFramework.FileHandling.read( powersource_node ) );

            var currentma_node = "%s/devices/platform/usb_gadget/current_mA".printf(sysfs_root);
            parseCurrentMa( FsoFramework.FileHandling.read( currentma_node ) );

            var hostconnected_node = "%s/devices/platform/usb_gadget/host_connected".printf(sysfs_root);
            parseHostConnected( FsoFramework.FileHandling.read( hostconnected_node ) );
        }

        private void onPlatformChangeEvent( GLib.HashTable<string, string> properties )
        {
            var modalias = properties.lookup( "MODALIAS" );
            if ( modalias == null || modalias != "platform:usb_gadget" )
                return;

            var action = properties.lookup( "G_ACTION" );
            if ( action == null )
                return;

            switch ( action )
            {
                case "POWER_STATE_CHANGED":
                    handlePowerStateChanged( properties );
                    break;
                case "HOST_STATE_CHANGED":
                    handleHostStateChanged( properties );
                    break;
                default:
                    break;
            }
        }

        private void parsePowerSource( string powersource )
        {
            switch ( powersource )
            {
                case "bus":
                    power_source = PowerSource.BUS;
                    break;
                case "none":
                    power_source = PowerSource.NONE;
                    break;
                case "charger":
                    power_source = PowerSource.CHARGER;
                    break;
                default:
                    break;
            }
        }

        private void parseCurrentMa( string currentma )
        {
            power_current_ma = int.parse( currentma );
        }

        private void parseHostConnected( string hostconnected )
        {
            host_connected = ( hostconnected == "1" );
        }

        private void handlePowerStateChanged( GLib.HashTable<string, string> properties )
        {
            var powersource = properties.lookup( "G_POWER_SOURCE" );
            if ( powersource != null )
                parsePowerSource( powersource );

            var currentma = properties.lookup( "G_CURRENT_MA" );
            if ( currentma != null )
                parseCurrentMa( currentma );
        }

        private void handleHostStateChanged( GLib.HashTable<string, string> properties )
        {
            var hostconnected = properties.lookup( "G_HOST_CONNECTED" );
            if ( hostconnected == null )
                return;

            parseHostConnected( hostconnected );
        }

        public override string repr()
        {
            return "<>";
        }
    }

    private class UsbGadgetPowerSupply :
        FreeSmartphone.Device.PowerSupply,
        FsoFramework.AbstractObject
    {
        private FsoFramework.Subsystem subsystem;
        private UsbGadgetListener usbgadget;

        internal FreeSmartphone.Device.PowerStatus status = FreeSmartphone.Device.PowerStatus.UNKNOWN;

        private void updatePowerStatus()
        {
            var next_status = FreeSmartphone.Device.PowerStatus.UNKNOWN;

            if ( usbgadget.power_source == UsbGadgetListener.PowerSource.BUS ||
                 usbgadget.power_source == UsbGadgetListener.PowerSource.CHARGER )
            {
                next_status = FreeSmartphone.Device.PowerStatus.ONLINE;
            }
            else
            {
                next_status = FreeSmartphone.Device.PowerStatus.OFFLINE;
            }

            if ( next_status != status )
            {
                status = next_status;
                power_status( status ); // DBUS SIGNAL
            }
        }

        //
        // public
        //

        public UsbGadgetPowerSupply( FsoFramework.Subsystem subsystem )
        {
            this.subsystem = subsystem;

            usbgadget = new UsbGadgetListener();
            usbgadget.initialize();
            usbgadget.hostStatusChanged.connect( () => { updatePowerStatus(); } );
            usbgadget.powerStatusChanged.connect( () => { updatePowerStatus(); } );

            updatePowerStatus();

            subsystem.registerObjectForService<FreeSmartphone.Device.PowerSupply>( FsoFramework.Device.ServiceDBusName,
                    "%s/%u".printf( FsoFramework.Device.PowerSupplyServicePath, 1 ), this );
        }

        public override string repr()
        {
            return "<>";
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
            return status;
        }

        public async int get_capacity() throws DBusError, IOError
        {
            return -1;
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
        private int current_capacity = -1;
        private int critical_capacity = -1;
        private bool present = true;
        private bool _skip_authentication = false;
        private UsbGadgetListener usbgadget;

        internal FreeSmartphone.Device.PowerStatus status = FreeSmartphone.Device.PowerStatus.UNKNOWN;

        //
        // private
        //

        private void updatePowerStatus()
        {
            var next_capacity = readRawCapacity();
            var next_status = FreeSmartphone.Device.PowerStatus.UNKNOWN;

            if ( next_capacity < current_capacity &&
                 usbgadget.power_source == UsbGadgetListener.PowerSource.NONE )
            {
                next_status = FreeSmartphone.Device.PowerStatus.DISCHARGING;
            }
            else if ( next_capacity > current_capacity && 
                      ( usbgadget.power_source == UsbGadgetListener.PowerSource.BUS ||
                        usbgadget.power_source == UsbGadgetListener.PowerSource.CHARGER ) )
            {
                next_status = FreeSmartphone.Device.PowerStatus.CHARGING;
            }
            else if ( next_capacity == 100 )
            {
                next_status = FreeSmartphone.Device.PowerStatus.FULL;
            }
            else if ( next_capacity <= critical_capacity )
            {
                next_status = FreeSmartphone.Device.PowerStatus.CRITICAL;
            }
            else if ( next_capacity == 0 )
            {
                next_status = FreeSmartphone.Device.PowerStatus.EMPTY;
            }
            else
            {
                if ( usbgadget.power_source == UsbGadgetListener.PowerSource.BUS ||
                     usbgadget.power_source == UsbGadgetListener.PowerSource.CHARGER )
                {
                    next_status = FreeSmartphone.Device.PowerStatus.CHARGING;
                }
                else
                {
                    next_status = FreeSmartphone.Device.PowerStatus.DISCHARGING;
                }
            }

            if ( next_status != FreeSmartphone.Device.PowerStatus.UNKNOWN &&
                 next_status != status)
            {
                status = next_status;
                power_status( status ); // DBUS SIGNAL
            }

            if ( next_capacity != current_capacity )
            {
                current_capacity =  next_capacity;
                capacity( current_capacity );
            }
        }

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

        private int readRawCapacity()
        {
            if ( !present )
            {
                return -1;
            }

            return int.parse( FsoFramework.FileHandling.read( Path.build_filename( slave_node, "getpercent" ) ) );
        }

        //
        // public
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
                status = FreeSmartphone.Device.PowerStatus.REMOVED;
                current_capacity = -1;
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
            subsystem.registerObjectForService<FreeSmartphone.Device.PowerSupply>( FsoFramework.Device.ServiceDBusName,
                    "%s/%u".printf( FsoFramework.Device.PowerSupplyServicePath, 0 ), this );

            critical_capacity = FsoFramework.theConfig.intValue( @"$(POWERSUPPLY_MODULE_NAME)/battery", "critical", 10);
            current_capacity = readRawCapacity();

            var poll_timout = FsoFramework.theConfig.intValue( @"$(POWERSUPPLY_MODULE_NAME)/battery", "poll_timeout", 10);

            usbgadget = new UsbGadgetListener();
            usbgadget.initialize();
            usbgadget.hostStatusChanged.connect( () => { updatePowerStatus(); } );
            usbgadget.powerStatusChanged.connect( () => { updatePowerStatus(); } );

            GLib.Timeout.add (poll_timout, ()=> {
                updatePowerStatus();
                return true;
            });

            logger.info( "Created new PowerSupply object." );
        }

        public override string repr()
        {
            return "<>";
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
            return status;
        }

        public async int get_capacity() throws DBusError, IOError
        {
            return current_capacity;
        }
    }

    /**
     * @class PowerSupply
     **/
    public class PowerSupply : FreeSmartphone.Device.PowerSupply,
                               FsoFramework.AbstractObject
    {
        private BatteryPowerSupply battery;
        private UsbGadgetPowerSupply usbgadget;

        private async FreeSmartphone.Device.PowerStatus fetchCurrentPowerStatus() throws DBusError, IOError
        {
            FreeSmartphone.Device.PowerStatus status = FreeSmartphone.Device.PowerStatus.UNKNOWN;

            // If the charger is connected we set the aggregated status in any case to AC
            // as we need to indicate that the charger is still connected when we are
            // already fully charged. Otherwise our current status is the battery status.

            if ( usbgadget != null && usbgadget.status == FreeSmartphone.Device.PowerStatus.ONLINE )
                status = FreeSmartphone.Device.PowerStatus.AC;
            else if ( battery != null )
                status = battery.status;

            return status;
        }

        private async int fetchCurrentCapacity() throws DBusError, IOError
        {
            int result = -1;

            if ( battery != null )
                result = yield battery.get_capacity();

            return result;
        }

        //
        // public
        //

        public PowerSupply( FsoFramework.Subsystem subsystem )
        {
            /* Create all necessary sub-modules */
            if ( config.hasSection( @"$(POWERSUPPLY_MODULE_NAME)/battery" ) )
                battery = new BatteryPowerSupply( subsystem );
            if ( config.hasSection( @"$(POWERSUPPLY_MODULE_NAME)/usb_gadget" ) )
                usbgadget = new UsbGadgetPowerSupply( subsystem );

            subsystem.registerObjectForService<FreeSmartphone.Device.PowerSupply>( FsoFramework.Device.ServiceDBusName,
                    FsoFramework.Device.PowerSupplyServicePath, this );
        }

        public override string repr()
        {
            return "<PalmPre.PowerSupply @ >";
        }

        //
        // FreeSmartphone.Device.PowerStatus (DBUS API)
        //

        public async FreeSmartphone.Device.PowerStatus get_power_status() throws DBusError, IOError
        {
            var result = yield fetchCurrentPowerStatus();
            return result;
        }

        public async int get_capacity() throws DBusError, IOError
        {
            var result = yield fetchCurrentCapacity();
            return result;
        }
    }

} /* namespace PalmPre */

// vim:ts=4:sw=4:expandtab
