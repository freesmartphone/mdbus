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

namespace N900
{
    /**
     * Bluetooth power control for Nokia N900
     **/
    class BluetoothPowerControl : FsoDevice.BasePowerControl
    {
        private FsoFramework.Subsystem subsystem;
        private string sysfsnode;
        private string name;
        private string wl12xx;

        public BluetoothPowerControl( FsoFramework.Subsystem subsystem, string sysfsnode, string wl12xx )
        {
            base( Path.build_filename( sysfsnode, "power_on" ) );
            this.subsystem = subsystem;
            this.sysfsnode = sysfsnode;
            this.name = Path.get_basename( sysfsnode );
            this.wl12xx = wl12xx;

            subsystem.registerObjectForServiceWithPrefix<FreeSmartphone.Device.PowerControl>( FsoFramework.Device.ServiceDBusName,
                FsoFramework.Device.PowerControlServicePath, this );

            logger.info( "Created." );
        }

        public override bool getPower()
        {
            return false;
        }

        public override void setPower( bool on )
        {
            if ( !on )
            {
                Posix.system( "killall bluetoothd; killall -9 bluetoothd" );
                Posix.system( "modprobe -r hci_h4p" );
                FsoFramework.FileHandling.write( "0", Path.build_filename( wl12xx, "bt_coex_mode" ) );
                return;
            }

            Posix.system( "modprobe hci_h4p" );
            FsoFramework.FileHandling.write( "00:11:22:33:44:55", Path.build_filename( sysfsnode, "bdaddr" ) );
            Posix.system( "modprobe -r hci_h4p" );
            Posix.system( "modprobe hci_h4p" );
            FsoFramework.FileHandling.write( "1", Path.build_filename( wl12xx, "bt_coex_mode" ) );
        }
    }

    /**
     * WiFi power control for Nokia N900
     **/
    class WiFiPowerControl : FsoDevice.BasePowerControl
    {
        private FsoFramework.Subsystem subsystem;
        private string sysfsnode;
        private string name;

        public WiFiPowerControl( FsoFramework.Subsystem subsystem, string sysfsnode )
        {
            base( Path.build_filename( sysfsnode, null ) );
            this.subsystem = subsystem;
            this.sysfsnode = sysfsnode;
            this.name = Path.get_basename( sysfsnode );

            subsystem.registerObjectForServiceWithPrefix<FreeSmartphone.Device.PowerControl>( FsoFramework.Device.ServiceDBusName,
                FsoFramework.Device.PowerControlServicePath, this );

            logger.info( "Created." );
        }

        public override bool getPower()
        {
            return false;
        }

        public override void setPower( bool on )
        {
        }
    }

} /* namespace */

// vim:ts=4:sw=4:expandtab
