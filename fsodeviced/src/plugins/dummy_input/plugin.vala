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
using Gee;

namespace Dummy
{
    internal const string DUMMY_INPUT_PLUGIN_NAME = "fsodevice.dummy_input";

/**
 * Implementation of org.freesmartphone.Device.Input for the dummy Input Device
 **/
class InputDevice : FreeSmartphone.Device.Input, FsoDevice.SignallingInputDevice, FsoFramework.AbstractObject
{
    FsoFramework.Subsystem subsystem;
    private int32 val;

    public InputDevice( FsoFramework.Subsystem subsystem )
    {
        this.subsystem = subsystem;

        subsystem.registerServiceName( FsoFramework.Device.ServiceDBusName );
        subsystem.registerServiceObject( FsoFramework.Device.ServiceDBusName, "%s/99".printf( FsoFramework.Device.InputServicePath ), this );

        val = 1;
        Timeout.add_seconds( 2, emitDummyEvent );

        logger.info( @"Created new DummyInputDevice" );
    }

    public override string repr()
    {
        return @"<42>";
    }

    private bool emitDummyEvent()
    {
        var event = Linux.Input.Event() { type = Linux.Input.EV_KEY, code = (uint16)Linux.Input.KEY_ESC, value = val };
        val = 1 - val;

        // inject something to Aggregate Input Device
        this.receivedEvent( ref event );
        return true;
    }

    //
    // FsoFramework.Device.Input (DBUS)
    //
    public async string get_id() throws DBus.Error
    {
        return "42";
    }

    public async string get_capabilities() throws DBus.Error
    {
        return "";
    }

}

} /* namespace */

internal Dummy.InputDevice instance;

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    instance = new Dummy.InputDevice( subsystem );
    return Dummy.DUMMY_INPUT_PLUGIN_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsodevice.dummy_input fso_register_function()" );
}

/**
 * This function gets called on plugin load time.
 * @return false, if the plugin operating conditions are present.
 * @note Some versions of glib contain a bug that leads to a SIGSEGV
 * in g_module_open, if you return true here.
 **/
/*public static bool g_module_check_init( void* m )
{
    var ok = FsoFramework.FileHandling.isPresent( DUMMY26.SYS_CLASS_LEDS );
    return (!ok);
}
*/
