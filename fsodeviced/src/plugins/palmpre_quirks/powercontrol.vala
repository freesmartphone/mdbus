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

        public WifiPowerControl( FsoFramework.Subsystem subsystem )
        {
            this.subsystem = subsystem;

            is_active = false;
            debug = false;

            sirloin_wifi_mod = new FsoFramework.Kernel26Module( "sirloin_wifi" );
            libertas_mod = new FsoFramework.Kernel26Module( "libertas" );
            libertas_sdio_mod = new FsoFramework.Kernel26Module( "libertas_sdio" );

            modules = new Gee.ArrayList<FsoFramework.Kernel26Module>();
            modules.add(sirloin_wifi_mod);
            modules.add(libertas_mod);
            modules.add(libertas_sdio_mod);

            subsystem.registerServiceName( FsoFramework.Device.ServiceDBusName );
            subsystem.registerServiceObjectWithPrefix( FsoFramework.Device.ServiceDBusName, FsoFramework.Device.PowerControlServicePath, this );

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

                if ( debug )
                {
                    libertas_mod.arguments = "libertas_debug=0xffffffff";
                }
                else
                {
                    libertas_mod.arguments = "";
                }

                foreach ( FsoFramework.Kernel26Module mod in modules )
                {
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
                    if ( !mod.load() )
                    {
                        logger.error( @"Could not load module '$(mod.name)'; aborting WiFi powering process ..." );
                        return;
                    }
                }
            }
        }
    }

    /**
     * @class PowerControl
     **/
    public class PowerControl
    {
        private List<FsoDevice.BasePowerControlResource> resources;
        private List<FsoDevice.BasePowerControl> instances;

        public PowerControl( FsoFramework.Subsystem subsystem )
        {
            instances = new List<FsoDevice.BasePowerControl>();
            resources = new List<FsoDevice.BasePowerControlResource>();

            var wifi = new WifiPowerControl( subsystem );
            instances.append( wifi );
#if WANT_FSO_RESOURCE
            resources.append( new FsoDevice.BasePowerControlResource( wifi, "WiFi", subsystem ) );
#endif
        }
    }
}

