/*
 * Copyright (C) 2011-2012 Simon Busch <morphis@gravedo.de>
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

public class Device.ServiceProvider : FsoPreferences.ServiceProvider
{
    public static string MODULE_NAME = "fsopreferences.service_device";

    public override string name { get { return "device"; } }

    private FreeSmartphone.Device.Display display_service;

    construct
    {
        setup("service.device");
        Idle.add(() => { register_objects(); return false; });
    }

    private async void register_objects()
    {
        try
        {
            display_service = yield Bus.get_proxy<FreeSmartphone.Device.Display>(BusType.SYSTEM,
                "org.freesmartphone.odeviced", "/org/freesmartphone/Device/Display/0");
        }
        catch (GLib.Error error)
        {
            logger.critical("Could not initialize required FSO dbus objects: $(error.message)");
        }
    }

    private async void handle_display_brightness(int brightness)
    {
        if (display_service == null)
            return;

        try
        {
            yield display_service.set_brightness(brightness);
        }
        catch (GLib.Error error)
        {
            logger.error(@"Can't set display brightness to $(brightness): $(error.message)");
        }
    }

    protected override async void handle_write_operation(string name, GLib.Variant value)
    {
        switch (name)
        {
            case "display-brightness":
                handle_display_brightness(value.get_int32());
                break;
            default:
                break;
        }
    }

    public override string repr()
    {
        return @"<$name>";
    }
}

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    return Device.ServiceProvider.MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsopreferences.service_device fso_register_function" );
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
