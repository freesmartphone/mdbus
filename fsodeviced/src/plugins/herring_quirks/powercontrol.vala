/*
 * Copyright (C) 2012 Simon Busch <morphis@gravedo.de>
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

namespace Herring
{
    internal class WiFiPowerControl : FsoDevice.BasePowerControl
    {
        private FsoDevice.BasePowerControlResource resource;
        private bool powered = false;
        private FsoFramework.Kernel26Module module;
        private bool firmware_available = false;

        public WiFiPowerControl( FsoFramework.Subsystem subsystem )
        {
            var module_name = @"$(Herring.MODULE_NAME)/wifi_power_control";
            var iface_name = FsoFramework.theConfig.stringValue( module_name, "iface_name", "wlan0" );
            var firmware_path = FsoFramework.theConfig.stringValue( module_name, "firmware_path", "/lib/firmware/fw_bcm4329.bin" );
            var nvram_path = FsoFramework.theConfig.stringValue( module_name, "nvram_path", "/lib/firmware/nvram_net.txt" );

            firmware_available = FsoFramework.FileHandling.isPresent( firmware_path ) &&
                                 FsoFramework.FileHandling.isPresent( nvram_path );

            module = new FsoFramework.Kernel26Module( "bcm4329" );
            module.arguments = "iface_name=$(iface_name) firmware_path=$(firmware_path) nvram_path=$(nvram_path)";

            subsystem.registerObjectForServiceWithPrefix<FreeSmartphone.Device.PowerControl>(
                FsoFramework.Device.ServiceDBusName, FsoFramework.Device.PowerControlServicePath, this );

            Idle.add( () => {
                this.resource = new FsoDevice.BasePowerControlResource( this, "WiFi", subsystem );
                return false;
            } );

            logger.info( "Created." );
        }

        public override bool getPower()
        {
            return powered;
        }

        public override void setPower( bool on )
        {
            if ( ( powered && on ) || ( !powered && !on ) )
                return;

            if ( on && ( !firmware_available || !module.available ) )
            {
                logger.warning( "Tried to enable WiFi but needed kernel module or firmware is not available" );
                return;
            }

            if ( on )
            {
                if ( !module.load() )
                {
                    logger.error( @"Failed to load kernel module $(module.name) with arguments \"$(module.arguments)\" to enable WiFi device" );
                    return;
                }

                logger.debug( @"Successfully enabled WiFi device" );
                powered = true;
            }
            else
            {
                if ( !module.unload() )
                {
                    logger.error( @"Failed to unload kernel module $(module.name) to disable WiFi device" );
                    return;
                }

                logger.debug( @"Successfully disabled WiFi device" );
                powered = false;
            }
        }
    }
}

// vim:ts=4:sw=4:expandtab
