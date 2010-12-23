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
    /**
     * @class TouchscreenManager
     **/
    public class TouchscreenManager : FsoFramework.AbstractObject
    {
        private FsoFramework.Subsystem subsystem;
        private FsoFramework.GProcessGuard tsmd_process;
        private FreeSmartphone.Device.Display odeviced_display;
        private string tsmd_path;
        private string tsmd_args;

        //
        // public methods
        //

        public TouchscreenManager( FsoFramework.Subsystem subsystem )
        {
            this.subsystem = subsystem;
            this.tsmd_process = new FsoFramework.GProcessGuard();

            tsmd_path = config.stringValue(@"$(MODULE_NAME)/touchscreen", "tsmd_path", "/usr/bin/tsmd");
            tsmd_args = config.stringValue(@"$(MODULE_NAME)/touchscreen", "tsmd_args", "-n /dev/touchscreen");

            logger.debug( @"Starting tsmd with: '$(tsmd_path) $(tsmd_args)'" );

            if ( !FsoFramework.FileHandling.isPresent( tsmd_path ) )
            {
                logger.critical(@"tsmd binary is not available on path '$(tsmd_path)'. Not installed?");
                return;
            }

            tsmd_process.setAutoRelaunch( true );
            string cmdline = @"$(tsmd_path) $(tsmd_args)";
            tsmd_process.launch( cmdline.split(" ") );

            if (!tsmd_process.isRunning())
            {
                logger.critical( "Could not launch tsmd binary. You will have to stay without touchscreen support ..." );
                return;
            }

            try
            {
                /* setup our dbus signal handler we need to react when the display goes on or off */
                odeviced_display = Bus.get_proxy_sync<FreeSmartphone.Device.Display>( BusType.SYSTEM, FsoFramework.Device.ServiceDBusName, FsoFramework.Device.DisplayServicePath );
                odeviced_display.backlight_power.connect( onBacklightPowerChanged );
            }
            catch ( DBusError e )
            {
                logger.error( @"Could not connect to odeviced's display resource $(e.message); Touchscreen functionality will be very unstable ..." );
                return;
            }
            catch ( IOError e )
            {
                logger.error( @"Could not connect to odeviced's display resource $(e.message); Touchscreen functionality will be very unstable ..." );
                return;
            }


            logger.info("Successfully launched touchscreen manager");
        }

        public override string repr()
        {
            return "<>";
        }

        //
        // private methods
        //

        private void onBacklightPowerChanged( bool power )
        {
            // NOTE: we have to tell the tsm daemon that the touchscreen powers down as
            // then it have to close the touchscreen interface and have to reopen it when
            // display is powered again. If we don't do that the touchscreen reports after
            // the display is powered again value which are unusable for reporting good
            // input events.
            if ( power )
            {
                tsmd_process.sendSignal( Posix.SIGUSR1 );
            }
            else
            {
                tsmd_process.sendSignal( Posix.SIGUSR2 );
            }
        }
    }
}

