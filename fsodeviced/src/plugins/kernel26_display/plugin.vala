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

namespace Kernel26
{

class Display : FreeSmartphone.Device.Display,
                FreeSmartphone.Info,
                FsoFramework.AbstractObject
{
    private FsoFramework.Subsystem subsystem;
    static uint counter;

    private int max_brightness;
    private int current_brightness;
    private string sysfsnode;
    private int fb_fd = -1;

    const int FBIOBLANK = 0x4611;
    const int FB_BLANK_UNBLANK = 0;
    const int FB_BLANK_POWERDOWN = 4;

    public Display(FsoFramework.Subsystem subsystem, string sysfsnode)
    {
        this.subsystem = subsystem;
        this.sysfsnode = sysfsnode;
        this.max_brightness = FsoFramework.FileHandling.read( this.sysfsnode + "/max_brightness" ).to_int();

        this.current_brightness = _getBrightness();

        fb_fd = Posix.open( dev_fb0, Posix.O_RDONLY );
        if ( fb_fd == -1 )
            logger.warning( "Can't open %s (%s). Full display power control not available.".printf( dev_fb0, Posix.strerror( Posix.errno ) ) );

        subsystem.registerServiceName( FsoFramework.Device.ServiceDBusName );
        subsystem.registerServiceObject( FsoFramework.Device.ServiceDBusName,
                        "%s/%u".printf( FsoFramework.Device.DisplayServicePath, counter++ ),
                        this );

        logger.info( "Created new Display object, max brightness = %d".printf( max_brightness ) );
    }

    public override string repr()
    {
        return "<FsoFramework.Device.Display @ %s>".printf( this.sysfsnode );
    }

    private void _setBacklightPower( bool on )
    {
        if ( fb_fd != -1 )
            Posix.ioctl( fb_fd, FBIOBLANK, on ? FB_BLANK_UNBLANK : FB_BLANK_POWERDOWN );
    }

    private int _valueToPercent( int value )
    {
        double max = max_brightness;
        double v = value;
        return (int)(100.0 / max * v);
    }

    private int _percentToValue( int percent )
    {
        double p = percent;
        double max = max_brightness;
        double value;
        if ( percent >= 100 )
            value = max_brightness;
        else if ( percent <= 0 )
            value = 0;
        else
            value = p / 100.0 * max;
        return (int)value;
    }

    private int _getBrightness()
    {
        var value = FsoFramework.FileHandling.read( this.sysfsnode + "/actual_brightness" ).to_int();
        return _valueToPercent( value );
    }

    //
    // FreeSmartphone.Info (DBUS API)
    //
    public async HashTable<string, Value?> get_info()
    {
        string _leaf;
        var val = Value( typeof(string) );
        HashTable<string, Value?> info_table = new HashTable<string, Value?>( str_hash, str_equal );
        /* Just read all the files in the sysfs path and return it as a{ss} */
        try
        {
            Dir dir = Dir.open( this.sysfsnode, 0 );
            while ((_leaf = dir.read_name()) != null)
            {
                if( FileUtils.test (this.sysfsnode + "/" + _leaf, FileTest.IS_REGULAR) && _leaf != "uevent" )
                {
                    val.take_string(FsoFramework.FileHandling.read(this.sysfsnode + "/" + _leaf).strip());
                    info_table.insert (_leaf, val);
                }
            }
        }
        catch ( GLib.Error error )
        {
            logger.warning( error.message );
        }
        return info_table;
    }

    //
    // FreeSmartphone.Device.Display (DBUS API)
    //
    public async string get_name()
    {
        return Path.get_basename( sysfsnode );
    }

    public async void set_brightness( int brightness )
    {
        var value = _percentToValue( brightness );

        if ( current_brightness != value )
        {
            FsoFramework.FileHandling.write( value.to_string(), this.sysfsnode + "/brightness" );
            if ( current_brightness == 0 ) // previously we were off
                _setBacklightPower( true );
            else if ( value == 0 ) // now we are off
                _setBacklightPower( false );
            current_brightness = value;
        }
        logger.debug( "Brightness set to %d".printf( brightness ) );
    }

    public async int get_brightness()
    {
        return _getBrightness();
    }

    public async bool get_backlight_power()
    {
        return FsoFramework.FileHandling.read( this.sysfsnode + "/bl_power" ).to_int() == 0;
    }

    public async void set_backlight_power( bool power )
    {
        var value = power ? "0" : "1";
        FsoFramework.FileHandling.write( value, this.sysfsnode + "/bl_power" );
    }
}

}

static string dev_fb0;
static string sys_class_backlight;
List<Kernel26.Display> instances;

public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    // grab sysfs and dev paths
    var config = FsoFramework.theConfig;
    var sysfs_root = config.stringValue( "cornucopia", "sysfs_root", "/sys" );
    sys_class_backlight = "%s/class/backlight".printf( sysfs_root );
    var dev_root = config.stringValue( "cornucopia", "dev_root", "/dev" );
    dev_fb0 = "%s/fb0".printf( dev_root );

    // scan sysfs path for leds
    var dir = Dir.open( sys_class_backlight, 0 );
    string entry = dir.read_name();
    while ( entry != null )
    {
        var filename = Path.build_filename( sys_class_backlight, entry );
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
