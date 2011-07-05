/*
 * Copyright (C) 2010-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *                         Simon Busch <morphis@gravedo.de>
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
using FsoFramework;

namespace PalmPre
{
    public static const string POWERCONTROL_MODULE_NAME = @"fsodevice.palmpre_quirks/powercontrol";

    /**
     * @class WifiPowerControl
     **/
    public class WifiPowerControl : FsoDevice.BasePowerControl
    {
        private FsoFramework.Kernel26Module sirloin_wifi_mod;
        private FsoFramework.Subsystem subsystem;
        private bool is_active; //interface powered and up

        public WifiPowerControl( FsoFramework.Subsystem subsystem )
        {
            base( "WiFi" );

            this.subsystem = subsystem;

            try
            {
                var iface = new Network.Interface( "eth0" );
                this.is_active = iface.is_up() ;
                iface.finish();
            }
            catch ( Error e )
            {
                this.is_active = false;
            }

            sirloin_wifi_mod = new FsoFramework.Kernel26Module( "sirloin_wifi" );

            subsystem.registerObjectForServiceWithPrefix<FreeSmartphone.Device.PowerControl>( FsoFramework.Device.ServiceDBusName, 
                FsoFramework.Device.PowerControlServicePath, this );

            logger.info( "Created." );
        }

        public override bool getPower()
        {
            return is_active;
        }

        private async void _setPower( bool power )
        {
            if ( power )
            {
                if ( is_active )
                {
                    logger.info( "Wifi is already powered; not powering it again." );
                    return;
                }

                logger.info( "Powering on WiFi ..." );

                var ok = sirloin_wifi_mod.load();
                if ( !ok )
                {
                    logger.error( "Loading WiFi kernel module failed!!!" );
                }
                else
                {
                    // after interface is available we need to activate it !BUT the kernel module
                    // needs time(750ms in average)!
                    Timeout.add( 900, () => { _setPower.callback(); return false; } );
                    yield;

                    try
                    {
                        var iface = new Network.Interface( "eth0" );
                        iface.up();
                        is_active = iface.is_up();
                        iface.finish();
                    }
                    catch ( Error e )
                    {
                        logger.error( "Failued to bring interface eth0 up: $(e.message)" );
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

                logger.info( "Powering off Wifi ..." );

                var ok = sirloin_wifi_mod.unload();
                if( !ok )
                {
                    logger.error( "Unloading WiFi kernel module failed!!!" );
                }
                else
                {
                    is_active = false;
                }
            }
        }

        public override void setPower( bool power )
        {
            // We need a async method for some operations
            _setPower( power );
        }
    }

    public class HciOverHsuartTransport : FsoFramework.HsuartTransport
    {
        // FIXME this should be in linux.vapi ... Can be found in drivers/bluetooth/hci_uart.h
        private static const uint N_HCI = 15;

        public HciOverHsuartTransport( string portname )
        {
            base( portname );
        }

        protected override void configure()
        {
            base.configure();

            uint flags = 0;

            // Set disclipe of our transport to HCI so the kernel detects that we have a
            // serial line which is able to talk HCI and loads the special driver for
            // this.
            Linux.ioctl( fd, Linux.Termios.TIOCSETD, N_HCI );

            // FIXME maybe we have to set the protocol type here via the HCIUARTSETPROTO
            // ioctl. There are H4, BCSP, 3WIRE, H4DS and LL as possible types.

            // NOTE We have to set the protocol here but there is currently no ioctl to do
            // this. How does the 2.6.24 kernel handle this? hciattach sets the protocol
            // for the specific bluetooth chip used in the device with the HCIUARTSETPROTO
            // ioctl.

            // NOTE webOS does the following with the btuart devnode:
            // 1692  open("/dev/btuart", O_RDWR|O_NOCTTY) = 5
            // 1692  ioctl(5, 0x40046807, 0xf)         = 0 ; set N_HCI via TIOCSETD
            // 1692  ioctl(5, 0x80086804, 0x9eaafabc)  = 0
            // 1692  ioctl(5, 0x40086805, 0x9eaafabc)  = 0
            // 1692  ioctl(5, 0x80086804, 0x9eaafabc)  = 0
            // 1692  ioctl(5, 0x40046809, 0x80)        = 0
        }
    }

    public class BluetoothPowerControl : FsoDevice.BasePowerControl
    {
        private const string DEFAULT_DEV_NAME = "/dev/btuart";
        private const string DEFAULT_RESET_NODE = "/sys/user_hw/pins/bt/reset/level";
        private FsoFramework.Subsystem subsystem;
        private FsoFramework.BaseTransport transport;
        private bool power_status;

        public BluetoothPowerControl( FsoFramework.Subsystem subsystem )
        {
            base( "Bluetooth" );
            this.subsystem = subsystem;
            this.power_status = false;

            subsystem.registerObjectForServiceWithPrefix<FreeSmartphone.Device.PowerControl>( FsoFramework.Device.ServiceDBusName,
                                                                                              FsoFramework.Device.PowerControlServicePath,
                                                                                              this );
            logger.info( "Created." );
        }

        public override bool getPower()
        {
            return power_status;
        }

        public override void setPower( bool power )
        {
            // Only power on when we are not already powered on
            if ( !power_status && power )
            {
                // Reset bluetooth chip first
                assert( logger.debug( "Reseting bluetooth chip ..." ) );
                FsoFramework.FileHandling.write( "0", DEFAULT_RESET_NODE );
                Posix.sleep( 2 );
                FsoFramework.FileHandling.write( "1", DEFAULT_RESET_NODE );

                assert( logger.debug( "Opening HCI over HSUart transport ... " ) );
                transport = new HciOverHsuartTransport( DEFAULT_DEV_NAME );
                transport.open();

                // FIXME set delegates for HUP and CLOSE events ..

                assert( logger.debug( "Successfully powerd on!" ) );
            }
            else if ( power_status && !power )
            {
                assert( logger.debug( "Closing HCI over HSUart transport ... " ) );
                transport.close();
            }

            power_status = power;
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
#if WANT_FSO_RESOURCE
                resources.append( new FsoDevice.BasePowerControlResource( wifi, "WiFi", subsystem ) );
#endif
            }

            if ( config.hasSection( @"$(POWERCONTROL_MODULE_NAME)/bluetooth" ) )
            {
                var bt = new BluetoothPowerControl( subsystem );
                instances.append( bt );
#if WANT_FSO_RESOURCE
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

// vim:ts=4:sw=4:expandtab
