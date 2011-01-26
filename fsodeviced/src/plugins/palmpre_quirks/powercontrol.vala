/*
 * Copyright (C) 2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
    public static const string POWERCONTROL_MODULE_NAME = @"fsodevice.palmpre_quirks/powercontrol";

    /**
     * @class WifiPowerControl
     **/
    public class WifiPowerControl : FsoDevice.BasePowerControl
    {
        private FsoFramework.Kernel26Module sirloin_wifi_mod;
        private FsoFramework.Kernel26Module libertas_mod;
        private FsoFramework.Kernel26Module libertas_sdio_mod;
        private Gee.ArrayList<FsoFramework.Kernel26Module> modules;
        private FsoFramework.Subsystem subsystem;
        private bool is_active;
        private bool debug;
        private string firmware_name;
        private string firmware_helper_name;

        public WifiPowerControl( FsoFramework.Subsystem subsystem )
        {
            base( "WiFi" );

            this.subsystem = subsystem;
            this.is_active = false;

            debug = config.boolValue( @"$(POWERCONTROL_MODULE_NAME)/wifi", "debug", false );
            firmware_name = config.stringValue( @"$(POWERCONTROL_MODULE_NAME)/wifi", "firmware_name", "sd8686.bin" );
            firmware_helper_name = config.stringValue( @"$(POWERCONTROL_MODULE_NAME)/wifi", "firmware_helper_name", "sd8686_helper.bin" );

            logger.debug( @"configuration: debug = $(debug) firmware_name = $(firmware_name) firmware_helper_name = $(firmware_helper_name)" );

            sirloin_wifi_mod = new FsoFramework.Kernel26Module( "sirloin_wifi" );
            libertas_mod = new FsoFramework.Kernel26Module( "libertas" );
            libertas_sdio_mod = new FsoFramework.Kernel26Module( "libertas_sdio" );

            /* build arguments string for libertas_sdio module */
            libertas_sdio_mod.arguments = @"fw_name=$(firmware_name) helper_name=$(firmware_helper_name)";

            /* if we are in debug mode than we have to adjust libertas module params */
            if ( debug )
            {
                libertas_mod.arguments = "libertas_debug=0xffffffff";
            }

            modules = new Gee.ArrayList<FsoFramework.Kernel26Module>();
            modules.add(sirloin_wifi_mod);
            modules.add(libertas_mod);
            modules.add(libertas_sdio_mod);

            subsystem.registerObjectForServiceWithPrefix<FreeSmartphone.Device.PowerControl>( FsoFramework.Device.ServiceDBusName, FsoFramework.Device.PowerControlServicePath, this );

            logger.info( "Created." );
        }

        public override bool getPower()
        {
            return is_active;
        }

        public override void setPower( bool power )
        {
            if ( power )
            {
                if ( is_active )
                {
                    logger.info( "Wifi is already powered; not powering it again." );
                    return;
                }

                foreach ( FsoFramework.Kernel26Module mod in modules )
                {
                    logger.debug( @"Loading module $(mod.name) with arguments '$(mod.arguments)" );

                    if ( !mod.load() )
                    {
                        logger.error( @"Could not load module '$(mod.name)'; aborting WiFi powering process ..." );
                        return;
                    }
                }
            }
            else
            {
                if ( !is_active )
                {
                    logger.info( "WiFi is not powered; not powering it off." );
                    return;
                }

                for ( var n = modules.size - 1; n >= 0; n-- )
                {
                    var mod = modules.get( n );

                    logger.debug( @"Unloading module $(mod.name)" );

                    if ( !mod.load() )
                    {
                        logger.error( @"Could not load module '$(mod.name)'; aborting WiFi powering process ..." );
                        return;
                    }
                }
            }
        }
    }

    public class BluetoothPowerControl : FsoDevice.BasePowerControl
    {
        private const string DEFAULT_DEV_NAME = "/dev/btuart";
        private const string DEFUALT_POWER_NODE = "/sys/user_hw/pins/bt/reset/level";
        private FsoFramework.Subsystem subsystem;
        private bool is_active;

        public BluetoothPowerControl( FsoFramework.Subsystem subsystem )
        {
            base( "Bluetooth" );
            this.subsystem = subsystem;
        }

        public override bool getPower()
        {
            return is_active;
        }

        public override void setPower( bool power )
        {
        }
    }

    /**
     * @class PowerControl
     **/
    public class PowerControl : FsoFramework.AbstractObject
    {
        private List<FsoDevice.BasePowerControlResource> resources;
        private List<FsoDevice.BasePowerControl> instances;

        public PowerControl( FsoFramework.Subsystem subsystem )
        {
            instances = new List<FsoDevice.BasePowerControl>();
            resources = new List<FsoDevice.BasePowerControlResource>();

            if ( config.hasSection( @"$(POWERCONTROL_MODULE_NAME)/wifi" ) )
            {
                var wifi = new WifiPowerControl( subsystem );
                instances.append( wifi );
                var bt = new BluetoothPowerControl( subsystem );
                instances.append( bt );
#if WANT_FSO_RESOURCE
                resources.append( new FsoDevice.BasePowerControlResource( wifi, "WiFi", subsystem ) );
                resources.append( new FsoDevice.BasePowerControlResource( bt, "Bluetooth", subsystem ) );
#endif
            }
        }

        public override string repr()
        {
            return "<PalmPre.PowerControl @ >";
        }
    }
}
