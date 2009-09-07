/**
 * Copyright (C) 2009 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

namespace Hardware
{
    internal char[] buffer;
    internal const uint BUFFER_SIZE = 512;

    internal const string HW_ACCEL_PLUGIN_NAME = "fsodevice.accelerometer";

/**
 * Implementation of org.freesmartphone.Device.Orientation for an Accelerometer device
 **/
class Accelerometer : /* FreeSmartphone.Device.Orientation, */ FsoFramework.AbstractObject
{
    private FsoFramework.Subsystem subsystem;
    //private FsoDevice.IAccelerometer device;

    public Accelerometer( FsoFramework.Subsystem subsystem /* , FsoDevice.IAccelerometer device */ )
    {
        this.subsystem = subsystem;
        //this.device = device;

        /*
        Idle.add( onIdle );

        // FIXME: Reconsider using /org/freesmartphone/Device/Input instead of .../IdleNotifier
        subsystem.registerServiceName( FsoFramework.Device.ServiceDBusName );
        subsystem.registerServiceObject( FsoFramework.Device.ServiceDBusName,
                                        "%s/0".printf( FsoFramework.Device.IdleNotifierServicePath ),
                                        this );

        var display_resource_allows_dim = config.boolValue( KERNEL_IDLE_PLUGIN_NAME, "display_resource_allows_dim", false );
        displayResourcePreventState = display_resource_allows_dim ? FreeSmartphone.Device.IdleState.IDLE_PRELOCK : FreeSmartphone.Device.IdleState.IDLE_DIM;
        */
    }

    public override string repr()
    {
        return "";
        //return "<%s>".printf( sysfsnode );
    }
}

} /* namespace */

internal Hardware.Accelerometer instance;


/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    // grab accelerometer type
    var config = FsoFramework.theMasterKeyFile();
    var type = config.stringValue( Hardware.HW_ACCEL_PLUGIN_NAME, "device_type", "" );

    // create one and only instance
    instance = new Hardware.Accelerometer( subsystem /*, plugin */ );

    return Hardware.HW_ACCEL_PLUGIN_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    debug( "input fso_register_function()" );
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