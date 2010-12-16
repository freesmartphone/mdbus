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
    /**
     * @class TouchscreenManager
     **/
    public class TouchscreenManager : FsoFramework.AbstractObject
    {
        private FsoFramework.Subsystem subsystem;
        private FsoFramework.GProcessGuard process;
        private string tsmd_path;
        private string tsmd_args;

        //
        // public methods
        //

        public TouchscreenManager( FsoFramework.Subsystem subsystem )
        {
            string cmdline = "";

            this.subsystem = subsystem;
            this.process = new FsoFramework.GProcessGuard();

            tsmd_path = config.stringValue(@"$(MODULE_NAME).touchscreen", "tsmd_path", "/usr/bin/tsmd");
            tsmd_args = config.stringValue(@"$(MODULE_NAME).touchscreen", "tsmd_args", "-n /dev/touchscreen");

            logger.debug(@"Starting tsmd with: '$(tsmd_path) $(tsmd_args)'");

            if (!FsoFramework.FileHandling.isPresent(tsmd_path))
            {
                logger.critical(@"tsmd binary is not available on path '$(tsmd_path)'. Not installed?");
                return;
            }

            process.setAutoRelaunch(true);
            cmdline = @"$(tsmd_path) $(tsmd_args)";
            process.launch(cmdline.split(" "));

            if (!process.isRunning())
            {
                logger.critical("Could not launch tsmd binary. You will have to stay without touchscreen support ...");
                return;
            }

            /* setup our dbus signal handlers we need to react when the display goes off */
            /* FIXME we need some dbus signal in our API to listen for this */

            logger.info("Successfully launched touchscreen manager");
        }

        public override string repr()
        {
            return "<FsoFramework.Device.TouchscreenManager @ >";
        }
    }
} /* namespace */

