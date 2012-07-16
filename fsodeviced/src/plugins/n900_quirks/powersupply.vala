/*
 * Copyright (C) 2010-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
    const string N900_CHARGER_I2C_FILE = "/dev/i2c-2";

    const uint8 N900_CHARGER_I2C_DEVICE = 0x55;
    const uint8 N900_CHARGER_READ_CAPACITY = 0x0b;

    public errordomain I2C_ERROR
    {
        SELECT_SLAVE_DEVICE,
        READ_FROM_DEVICE,
        WRITE_TO_DEVICE
    }

    /**
     * Implementation of org.freesmartphone.Device.PowerSupply for the Nokia N900 device
     **/
    class N900 : FreeSmartphone.Device.PowerSupply,
                 FreeSmartphone.Info,
                 FsoFramework.AbstractObject
    {
        FsoFramework.Subsystem subsystem;

        private string sysfsnode;
        private uint8 charging_mode = 0x08;

        // internal (accessible for aggregate power supply)
        internal string name;
        internal string typ;
        internal FreeSmartphone.Device.PowerStatus status = FreeSmartphone.Device.PowerStatus.UNKNOWN;
        internal bool present;
        internal int fd = -1;

        internal int capacity = -1;

        public N900( FsoFramework.Subsystem subsystem, string sysfsnode )
        {
            this.subsystem = subsystem;
            this.sysfsnode = sysfsnode;

            fd = Posix.open( N900_CHARGER_I2C_FILE, Posix.O_RDWR );
            if ( fd == -1 )
            {
                logger.warning( @"Can't open $N900_CHARGER_I2C_FILE: $(strerror(errno)). Powersupply will not available." );
                return;
            }

            FsoFramework.BaseKObjectNotifier.addMatch( "change", "power_supply", onPowerSupplyChangeNotification );

            Idle.add( onIdle );

            //subsystem.registerServiceName( FsoFramework.Device.ServiceDBusName );
            //subsystem.registerServiceObjectWithPrefix( FsoFramework.Device.ServiceDBusName, FsoFramework.Device.PowerSupplyServicePath, this );

            logger.info( "Created" );
        }

        public override string repr()
        {
            return @"<$sysfsnode>";
        }

        private void pushMaskedByteToI2C( int file, uint8 mask, uint8 device, uint8 command, uint8 value ) throws I2C_ERROR
        {
            if ( Posix.ioctl( fd, Linux.I2C.SLAVE, device ) == -1)
            {
                throw new I2C_ERROR.SELECT_SLAVE_DEVICE( "Could not select slave device 0x%02X (%s)".printf( device, strerror(errno) ) );
            }
            int32 result = Linux.I2C.SMBUS.write_byte_data_masked( file, mask, command, value );
            if ( result == -1 )
            {
                throw new I2C_ERROR.WRITE_TO_DEVICE( "Could not write at 0x%02X:0x%02X (%s)".printf( device, command, strerror(errno) ) );
            }
        }

        private void pushByteToI2C( int file, uint8 device, uint8 command, uint8 value ) throws I2C_ERROR
        {
            if ( Posix.ioctl( fd, Linux.I2C.SLAVE, device ) == -1)
            {
                throw new I2C_ERROR.SELECT_SLAVE_DEVICE( "Could not select i2c slave device 0x%02X (%s)".printf( device, strerror(errno) ) );
            }
            int32 result = Linux.I2C.SMBUS.write_byte_data( file, command, value );
            if ( result == -1 )
            {
                throw new I2C_ERROR.WRITE_TO_DEVICE( "Could not write at 0x%02X:0x%02X (%s)".printf( device, command, strerror(errno) ) );
            }
        }

        private uint8 pullByteFromI2C( int file, uint8 device, uint8 command ) throws I2C_ERROR
        {
            if ( Posix.ioctl( fd, Linux.I2C.SLAVE, device ) == -1)
            {
                throw new I2C_ERROR.SELECT_SLAVE_DEVICE( "Could not select i2c slave device 0x%02X (%s)".printf( device, strerror(errno) ) );
            }
            int32 result = Linux.I2C.SMBUS.read_byte_data( file, command );
            if ( result == -1 )
            {
                throw new I2C_ERROR.READ_FROM_DEVICE( "Could not read at 0x%02X:0x%02X (%s)".printf( device, command, strerror(errno) ) );
            }
            return (uint8) result & 0xff;
        }

        private bool onTimeout()
        {
            try
            {
                var status = pullByteFromI2C( fd, 0x6b, 0x00 );
                logger.info( "Triggering charger while status is 0x%02X".printf( status ) );
                pushByteToI2C( fd, 0x6b, 0x00, 0x80 );
            }
            catch ( Error e )
            {
                logger.error( @"Error: $(e.message), abandoning charging" );
                return false;
            }
            return true;

            /*
            logger.debug( "Reading capacity from i2c..." );

            var ok = Posix.ioctl( fd, Linux.I2C.SLAVE, N900_CHARGER_I2C_DEVICE );
            if ( ok < 0 )
            {
                logger.warning( @"Can't change I2C SLAVE: $(strerror(errno))." );
                return true;
            }

            var res = Linux.I2C.SMBUS.read_byte_data( fd, N900_CHARGER_READ_CAPACITY );
            if ( res < 0 )
            {
                logger.warning( @"Can't i2c read_byte_data: $(strerror(errno))." );
                return true; // mainloop: don't call us again
            }
            logger.debug( @"i2c reports capacity as $(res)" );
            capacity = res;
            */
            return true; // mainloop: call us again
        }

        public void onPowerSupplyChangeNotification( HashTable<string,string> properties )
        {
            var name = properties.lookup( "POWER_SUPPLY_NAME" );
            if ( name != "isp1704" )
            {
                /* we ignore it since there is also a battery gauge(bq27200-0) */
                return;
            }
            string current_max = properties.lookup( "POWER_SUPPLY_CURRENT_MAX" );

            switch ( current_max )
            {
                case "1800":
                    charging_mode = 0xc8;
                    break;
                case "800":
                    charging_mode = 0x88;
                    break;
                case "500":
                    charging_mode = 0x48;
                    break;
                case "100":
                default:
                    /* default to 100mA */
                    charging_mode = 0x08;
                    break;
           }
           logger.info(@"charging mode $(current_max) -> $(charging_mode)" );
           Idle.add( onIdle );
        }

        public bool onIdle()
        {
            logger.info( "Disabling charger for configuration" );

            try
            {
                //i2cset -y 2 0x6b 0x01 0xcc # No limit, 3.4V weak threshold, enable term, charger disable
                pushByteToI2C( fd, 0x6b, 0x01, 0xcc );

                /*
                # Register 0x04
                # 8: reset
                # 4: 27.2mV  # charge current
                # 2: 13.6mV
                # 1: 6.8mV
                # 8: N/A
                # 4: 13.6mV # termination current
                # 2: 6.8mV
                # 1: 3.4mV
                # 7-1250 6-1150 5-1050 4-950 3-850 2-750 1-650 0-550
                # 7-400 6-350 5-300 4-250 3-200 2-150 1-100 0-50
                i2cset -y -m 0xFF 2 0x6b 0x04 0x50;
                */
                pushMaskedByteToI2C( fd, 0xff, 0x6b, 0x04, 0x50 );

                /*
                # Register 0x02
                # 8: .640 V
                # 4: .320 V
                # 2: .160 V
                # 1: .080
                # 8: .040
                # 4: .020 (+ 3.5)
                # 2: otg pin active at high (default 1)
                # 1: enable otg pin
                i2cset -y -m 0xfc 2 0x6b 0x02 0x8c;
                # 4.2 = 3.5 + .640 + .040 + .02 = 8c
                # 4.16 = 3.5 + .640V + .020 = 84
                # 4.1 = 3.5 + .320 + .160 + .08 + .04 = 78
                # 4.0 = 3.5 + .320 + .160 + .02 = 64
                # 3.9 = 3.5 + .320 + .080 = 50
                */
                pushMaskedByteToI2C( fd, 0xfc, 0x6b, 0x02, 0x8c );

                /*
                # Register 0x1
                # 8: 00 = 100, 01 = 500, 10 = 800mA
                # 4: 11 = no limit
                # 2: 200mV weak threshold default 1
                # 1: 100mV weak treshold defsult 1 (3.4 - 3.7)
                # 8: enable termination
                # 4: charger disable
                # 2: high imp mode
                # 1: boost
                i2cset -y 2 0x6b 0x01 0xc8;
                */
                pushByteToI2C( fd, 0x6b, 0x01, charging_mode);

                /*
                # Register 0x00
                # 8: Read:  OTG Pin Status
                #    Write: Timer Reset
                # 4: Enable Stat Pin
                # 2: Stat : 00 Ready 01 In Progress
                # 1:      : 10 Done  11 Fault
                # 8: Boost Mode
                # 4: Fault: 000 Normal 001 VBUS OVP 010 Sleep Mode
                # 2:        011 Poor input or Vbus < UVLO
                # 1:        100 Battery OVP 101 Thermal Shutdown
                #           110 Timer Fault 111 NA
                i2cset -y 2 0x6b 0x00 0x00;
                */
                pushByteToI2C( fd, 0x6b, 0x00, 0x00 );

                logger.info( "Charger programmed... sleeping 1 second" );
            }
            catch ( Error e )
            {
                logger.error( @"Error: $(e.message), aborting" );
                return false;
            }

            Timeout.add_seconds( 1, () => {
                onTimeout();
                return false;
            } );

            Timeout.add_seconds( 15, onTimeout );

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
            return capacity;
        }

        //
        // FreeSmartphone.Info (DBUS API)
        //
        public async HashTable<string,Value?> get_info() throws DBusError, IOError
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
        public async FreeSmartphone.Device.PowerStatus get_power_status() throws DBusError, IOError
        {
            return status;
        }

        public async int get_capacity() throws DBusError, IOError
        {
            return getCapacity();
        }
    }
} /* namespace */

// vim:ts=4:sw=4:expandtab
