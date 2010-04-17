/*
 * Copyright (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

namespace AmbientLight
{
    internal const string DEFAULT_INPUT_NODE = "input/event4";
    internal const int DARKNESS = 0;
    internal const int SUNLIGHT = 1000;

class PalmPre : FreeSmartphone.Device.AmbientLight, FsoFramework.AbstractObject
{
    FsoFramework.Subsystem subsystem;

    private string sysfsnode;
    private string resultnode;
    private string averagenode;
    private string pollintervalnode;

    private int maxvalue;
    private int minvalue;

    FsoFramework.Async.ReactorChannel input;

    public PalmPre( FsoFramework.Subsystem subsystem, string sysfsnode )
    {
        minvalue = DARKNESS;
        maxvalue = SUNLIGHT;

        this.subsystem = subsystem;
        this.sysfsnode = sysfsnode;

        this.resultnode = sysfsnode + "/result";
        this.averagenode = sysfsnode + "/average";
        this.pollintervalnode = sysfsnode + "/poll_interval";

        if ( !FsoFramework.FileHandling.isPresent( this.resultnode ) )
        {
            logger.error( @"Sysfs class is damaged, missing $(this.resultnode); skipping." );
            return;
        }

        var fd = Posix.open( GLib.Path.build_filename( devfs_root, DEFAULT_INPUT_NODE ), Posix.O_RDONLY );
        if ( fd == -1 )
        {
            logger.error( @"Can't open $devfs_root/$DEFAULT_INPUT_NODE: $(Posix.strerror(Posix.errno))" );
            return;
        }

        input = new FsoFramework.Async.ReactorChannel( fd, onInputEvent, sizeof( Linux.Input.Event ) );

        subsystem.registerServiceName( FsoFramework.Device.ServiceDBusName );
        subsystem.registerServiceObjectWithPrefix(
            FsoFramework.Device.ServiceDBusName,
            FsoFramework.Device.AmbientLightServicePath,
            this );

        logger.info( "Created" );

    }

    public override string repr()
    {
        return @"<$sysfsnode>";
    }

    private void onInputEvent( void* data, ssize_t length )
    {
        var event = (Linux.Input.Event*) data;
        if ( event->type != 3 || event->code != 40 )
        {
            assert( logger.debug( @"Unknown event w/ type $(event->type) and code $(event->code); ignoring" ) );
            return;
        }

        // send dbus signal
        this.ambient_light_brightness( _valueToPercent( (int)event->value ) );
    }

    private int _valueToPercent( int value )
    {
        double v = value;
        return (int)(100.0 / (maxvalue-minvalue) * (v-minvalue));
    }

    //
    // FreeSmartphone.Device.AmbientLight (DBUS API)
    //
    public async void get_ambient_light_brightness( out int brightness, out int timestamp ) throws FreeSmartphone.Error, DBus.Error
    {
        brightness = -1;
        timestamp = 0;
    }
}

} /* namespace */

static string sysfs_root;
static string devfs_root;
AmbientLight.PalmPre instance;

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    // grab sysfs paths
    var config = FsoFramework.theConfig;
    sysfs_root = config.stringValue( "cornucopia", "sysfs_root", "/sys" );
    devfs_root = config.stringValue( "cornucopia", "devfs_root", "/dev" );
    var dirname = GLib.Path.build_filename( sysfs_root, "class", "input", "input4" );
    if ( FsoFramework.FileHandling.isPresent( dirname ) )
    {
        instance = new AmbientLight.PalmPre( subsystem, dirname );
    }
    else
    {
        FsoFramework.theLogger.error( "No ambient light device found; ambient light object will not be available" );
    }
    return "fsodevice.ambientlight_palmpre";
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsodevice.ambientlight_palmpre fso_register_function()" );
}

/**
 * This function gets called on plugin load time.
 * @return false, if the plugin operating conditions are present.
 * @note Some versions of glib contain a bug that leads to a SIGSEGV
 * in g_module_open, if you return true here.
 **/
/*public static bool g_module_check_init( void* m )
{
    var ok = FsoFramework.FileHandling.isPresent( Kernel26.SYS_CLASS_LEDS );
    return (!ok);
}
*/
