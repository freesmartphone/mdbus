/*
 * plugin.vala
 * Written by Sudharshan "Sup3rkiddo" S <sudharsh@gmail.com>
 * All Rights Reserved
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */

using GLib;
using DisplayHelpers;

namespace Kernel26
{
    static const string SYS_CLASS_DISPLAY = "/sys/class/backlight";

    class Display : FsoFramework.Device.Display, GLib.Object
    {
        private FsoFramework.Subsystem subsystem;
        static FsoFramework.Logger logger;
        static uint counter;

        private int max_brightness;
        private int curr_brightness;
        private string sysfsnode;
        private int fb_fd;

        public Display(FsoFramework.Subsystem subsystem, string sysfsnode)
        {
            if (logger == null)
                logger = FsoFramework.createLogger( "fsodevice.kernel26_leds" );
            logger.info( "Created new Display for %s".printf( sysfsnode ) );

            this.subsystem = subsystem;
            this.sysfsnode = sysfsnode;
            this.max_brightness = FsoFramework.FileHandling.read(this.sysfsnode + "/max_brightness").to_int();

            this.curr_brightness = this.GetBrightness();
            try
            {
                var _fb = new IOChannel.file ("/dev/fb0", "r");
                this.fb_fd = _fb.unix_get_fd();
            }
            catch (GLib.Error error)
            {
                this.fb_fd = -1;
                logger.warning (error.message);
            }


            subsystem.registerServiceName( FsoFramework.Device.ServiceDBusName );
            subsystem.registerServiceObject( FsoFramework.Device.ServiceDBusName,
                            "%s/%u".printf( FsoFramework.Device.DisplayServicePath, counter++ ),
                            this );

        }


        public void SetBrightness(int brightness)
        {
            int value = GetBrightness();

            if(brightness > this.max_brightness)
            {
                logger.warning("Required brightness %d is greater than the maximum brighness supported by the display : %s".printf(brightness, this.sysfsnode));
                return;
            }

            if(this.curr_brightness!=value)
            {
                FsoFramework.FileHandling.write(brightness.to_string(), this.sysfsnode + "/brightness");
                if (this.curr_brightness == 0)
                    DisplayHelpers.set_fb(true, this.fb_fd);
                else if(value == 0)
                    DisplayHelpers.set_fb(false, this.fb_fd);
                this.curr_brightness = value;
            }
            logger.debug("Brightness set to %d".printf(brightness));
        }


        public int GetBrightness()
        {
            return FsoFramework.FileHandling.read(this.sysfsnode + "/actual_brightness").to_int();
        }


        public bool GetBacklightPower()
        {
            return FsoFramework.FileHandling.read(this.sysfsnode + "/bl_power").to_int() == 0;
        }


        public void SetBacklightPower(bool power)
        {
            int _val;
            if (power)
            _val = 0;
            else
                _val = 1;
            FsoFramework.FileHandling.write(_val.to_string(), this.sysfsnode + "/bl_power");
        }


        public HashTable<string, Value?> GetInfo()
        {
            string _leaf;
            Value val = new Value(typeof(string));
            HashTable<string, Value?> info_table = new HashTable<string, Value?>((HashFunc)str_hash,
                                                                                (EqualFunc)str_equal);
            /* Just read all the files in the sysfs path and return it as a{ss} */
            try
            {
                Dir dir = Dir.open (this.sysfsnode, 0);
                while ((_leaf = dir.read_name()) != null)
                {
                    if(FileUtils.test (this.sysfsnode + "/" + _leaf, FileTest.IS_REGULAR) && _leaf != "uevent")
                    {
                        val.take_string(FsoFramework.FileHandling.read(this.sysfsnode + "/" + _leaf).strip());
                        info_table.insert (_leaf, val);
                    }
                }
            }
            catch (GLib.Error error)
            {
                logger.warning (error.message);
            }
            return info_table;
        }

    }

}


List<Kernel26.Display> instances;


public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    // scan sysfs path for leds
    Dir dir = Dir.open( Kernel26.SYS_CLASS_DISPLAY, 0 );
    string entry = dir.read_name();
    while ( entry != null )
    {
        var filename = Path.build_filename( Kernel26.SYS_CLASS_DISPLAY, entry );
        instances.append( new Kernel26.Display( subsystem, filename ) );
        entry = dir.read_name();
    }
    return "fsodevice.kernel26_display";
}


[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    debug( "kernel26_display fso_register_function()" );
}
