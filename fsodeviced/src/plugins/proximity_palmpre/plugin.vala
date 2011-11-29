/*
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

namespace Proximity
{
    internal const string DEFAULT_INPUT_NODE = "input/event3";
    internal const int NEAR = 0;
    internal const int FAR = 100;

class PalmPre : FreeSmartphone.Device.Proximity,
                FreeSmartphone.Device.PowerControl,
                FsoFramework.AbstractObject
{
    FsoFramework.Subsystem subsystem;

    private string sysfsnode;
    private string powernode;

    private int maxvalue;
    private int minvalue;
    private long start_timestamp;
    private int _current_proximity = -1;
    private int _value_timestamp = -1;
    private int current_proximity {
        get {return _current_proximity; }
        set {
            if( value != _current_proximity)
            {
                _current_proximity = value;
                proximity(value);
                TimeVal tv = TimeVal();
                tv.get_current_time();
                _value_timestamp = (int)(tv.tv_sec - start_timestamp);
            }
        }
    }

    FsoFramework.Async.ReactorChannel input;

    public PalmPre( FsoFramework.Subsystem subsystem, string sysfsnode )
    {
        minvalue = FAR;
        maxvalue = NEAR;

        this.subsystem = subsystem;
        this.sysfsnode = sysfsnode;

        this.powernode = sysfsnode + "/enable_detection";

        if ( !FsoFramework.FileHandling.isPresent( this.powernode ) )
        {
            logger.error( @"Sysfs class is damaged, missing $(this.powernode); skipping." );
            return;
        }

        var fd = Posix.open( GLib.Path.build_filename( devfs_root, DEFAULT_INPUT_NODE ), Posix.O_RDONLY );
        if ( fd == -1 )
        {
            logger.error( @"Can't open $devfs_root/$DEFAULT_INPUT_NODE: $(Posix.strerror(Posix.errno))" );
            return;
        }

        input = new FsoFramework.Async.ReactorChannel( fd, onInputEvent, sizeof( Linux.Input.Event ) );

        subsystem.registerObjectForService<FreeSmartphone.Device.Proximity>( FsoFramework.Device.ServiceDBusName, FsoFramework.Device.ProximityServicePath, this );
        subsystem.registerObjectForService<FreeSmartphone.Device.PowerControl>( FsoFramework.Device.ServiceDBusName, FsoFramework.Device.ProximityServicePath, this );

        TimeVal tv = TimeVal();
        tv.get_current_time();
        start_timestamp = tv.tv_sec;
        //disable by default
        set_power( false );

        logger.info( "Created" );
    }

    public override string repr()
    {
        return @"<$sysfsnode>";
    }

    private void onInputEvent( void* data, ssize_t length )
    {
        var event = (Linux.Input.Event*) data;
        if ( event->type != 4 || event->code != 1 )
        {
            assert( logger.debug( @"Unknown event w/ type $(event->type), code $(event->code) and value $(event->value); ignoring" ) );
            return;
        }
        assert( logger.debug ( @"Using Proximity event with value $(event->value)"));
        current_proximity = _valueToPercent( event->value );
    }

    private int _valueToPercent( int value )
    {
        double v = value;
        return (int)(100.0 / (maxvalue-minvalue) * (v-minvalue));
    }

    //
    // FreeSmartphone.Device.Proximity (DBUS API)
    //
    public async void get_proximity( out int proximity, out int timestamp ) throws FreeSmartphone.Error, DBusError, IOError
    {
        proximity = current_proximity;
        timestamp = _value_timestamp;
    }

    //
    // FreeSmartphone.Device.PowerControl (DBUS API)
    //
    public async bool get_power() throws DBusError, IOError
    {
        var contents = FsoFramework.FileHandling.read( powernode ) ?? "";
        return contents.strip() == "1";
    }

    public async void set_power( bool on ) throws DBusError, IOError
    {
        var contents = on ? "1" : "0";
        FsoFramework.FileHandling.write( contents, powernode );
    }

}
/**
 * Implementation of org.freesmartphone.Resource for the Palmpre Proximity Resource
 **/
public class PalmPreResource : FsoFramework.AbstractDBusResource
{
    bool on = false;
    public PalmPreResource( FsoFramework.Subsystem subsystem )
    {
        base( "Proximity", subsystem );
    }
    public override async void enableResource()
    {
        if (on)
            return;
        yield instance.set_power( true );
        on = true;
    }

    public override async void disableResource()
    {
        if (!on)
            return;
        yield instance.set_power( false );
        on = false;
    }

    public override async void suspendResource()
    {
    }

    public override async void resumeResource()
    {
    }
}

} /* namespace */

static string sysfs_root;
static string devfs_root;
Proximity.PalmPre instance;
Proximity.PalmPreResource resource;

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
    devfs_root = config.stringValue( "cornucopia", "devfs_root", "/dev" );
    sysfs_root = config.stringValue( "cornucopia", "sysfs_root", "/sys" );
    var dirname = GLib.Path.build_filename( sysfs_root, "devices", "platform", "hsdl9100_proximity", "input", "input3" );
    if ( FsoFramework.FileHandling.isPresent( dirname ) )
    {
        instance = new Proximity.PalmPre( subsystem, dirname );
        resource = new Proximity.PalmPreResource( subsystem );
    }
    else
    {
        FsoFramework.theLogger.error( "No proximity device found; proximity object will not be available" );
    }
    return "fsodevice.proximity_palmpre";
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsodevice.proximity_palmpre fso_register_function()" );
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

// vim:ts=4:sw=4:expandtab