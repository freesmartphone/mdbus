/*
 * Copyright (C) 2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *               2010 Sebastian Krzyszkowiak <dos@dosowisko.net>
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
using Gee;

namespace Gpio
{
    internal const string GPIO_INPUT_PLUGIN_NAME = "fsodevice.gpio_input";

/**
 * Implementation of org.freesmartphone.Device.Input for the gpio Input Device
 **/
class InputDevice : FreeSmartphone.Device.Input, FsoDevice.SignallingInputDevice, FsoFramework.AbstractObject
{
    FsoFramework.Subsystem subsystem;
    string path;
    string node;
    string value;
    int code;
    
    public bool onInputEvent( IOChannel source, IOCondition condition )
    {
      if ( ( ( condition & IOCondition.IN  ) == IOCondition.IN  ) || ( ( condition & IOCondition.PRI ) == IOCondition.PRI ) ) {
        string readvalue = "";
        size_t c = 0;
        source.read_line (out readvalue, out c, null);
        logger.debug( @"got data from sysfs node: $value" );

	int32 val = (readvalue.strip() == this.value) ? 1 : 0;

	var event = Linux.Input.Event() { type = Linux.Input.EV_SW, code = (uint16)this.code, value = val };

        // inject something to Aggregate Input Device
        this.receivedEvent( ref event );
	
        source.seek_position(0, SeekType.SET);
        return true;
      }
      else {
        logger.error("onInputEvent error");
        return false;
      }
    }

    
    public InputDevice( FsoFramework.Subsystem subsystem, string path, int code, string value )
    {
        this.subsystem = subsystem;
        this.path = path;
	this.code = code;
	this.value = value;
	
        subsystem.registerServiceName( FsoFramework.Device.ServiceDBusName );
        subsystem.registerServiceObject( FsoFramework.Device.ServiceDBusName, "%s/gpio%d".printf( FsoFramework.Device.InputServicePath, code ), this );

        if ( !FsoFramework.FileHandling.isPresent( path ) )
        {
            logger.error( @"Sysfs class is damaged, missing $(path); skipping." );
            return;
        }

        string powernode = GLib.Path.build_filename( path, "disable" );
        string node = GLib.Path.build_filename( path, "state" );
        this.node = node;
	
	FsoFramework.FileHandling.write( "0", powernode );
	
        logger.debug( @"Trying to read from $(node)..." );

        var channel = new IOChannel.file( node, "r" );
        string readvalue = "";
        size_t c = 0;
        channel.read_to_end(out readvalue, out c);
        channel.seek_position(0, SeekType.SET);

        channel.add_watch( IOCondition.IN | IOCondition.PRI | IOCondition.ERR, onInputEvent );

        logger.info( @"Created new GpioInputDevice" );
    }

    public override string repr()
    {
        return @"<$(this.path)>";
    }

/*    private bool emitDummyEvent()
    {
        var event = Linux.Input.Event() { type = Linux.Input.EV_KEY, code = (uint16)Linux.Input.KEY_ESC, value = val };
        val = 1 - val;

        // inject something to Aggregate Input Device
        this.receivedEvent( ref event );
        return true;
    }*/

    //
    // FsoFramework.Device.Input (DBUS)
    //
    public async string get_id() throws DBus.Error
    {
        return this.path;
    }

    public async string get_capabilities() throws DBus.Error
    {
        return "";
    }

}

} /* namespace */

static string sysfs_root;
internal Gpio.InputDevice instance;

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

    var entries = config.keysWithPrefix( Gpio.GPIO_INPUT_PLUGIN_NAME, "node" );
    foreach ( var entry in entries )
    {
        var readvalue = config.stringValue( Gpio.GPIO_INPUT_PLUGIN_NAME, entry );
        //message( "got value '%s'", value );
        var values = readvalue.split( "," );
        if ( values.length != 3 )
        {
            FsoFramework.theLogger.warning( @"Config option $entry has not 3 elements. Ignoring." );
            continue;
        }
        var name = values[0];
        int code = values[1].to_int();
	var value = values[2];

	var dirname = GLib.Path.build_filename( sysfs_root, "devices", "platform", "gpio-switch", name);

	if ( FsoFramework.FileHandling.isPresent( dirname ) )
        {
            instance = new Gpio.InputDevice( subsystem, dirname, code, value );
        }
        else
        {
            FsoFramework.theLogger.error( "Definied gpio-switch - $(name) - device is not available" );
        }

    }
    
    return Gpio.GPIO_INPUT_PLUGIN_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsodevice.gpio_input fso_register_function()" );
}

/**
 * This function gets called on plugin load time.
 * @return false, if the plugin operating conditions are present.
 * @note Some versions of glib contain a bug that leads to a SIGSEGV
 * in g_module_open, if you return true here.
 **/
/*public static bool g_module_check_init( void* m )
{
    var ok = FsoFramework.FileHandling.isPresent( KERNEL26.SYS_CLASS_LEDS );
    return (!ok);
}
*/
