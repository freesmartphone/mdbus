/*
 * Copyright (C) 2009-2012 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *                    2010-2012 Sebastian Krzyszkowiak <seba.dos1@gmail.com>
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

namespace PowerControl
{

class Ifconfig : FsoDevice.ISimplePowerControl,
                 FreeSmartphone.Device.PowerControl,
                 FsoFramework.AbstractObject
{
    FsoFramework.Subsystem subsystem;
    string iface;
    bool power;

    public Ifconfig( FsoFramework.Subsystem subsystem, string iface )
    {
        this.subsystem = subsystem;
        this.iface = iface;
        this.power = false;

        subsystem.registerObjectForService<FreeSmartphone.Device.PowerControl>( FsoFramework.Device.ServiceDBusName, FsoFramework.Device.ProximityServicePath, this );

        logger.info( "Created" );
    }

    public override string repr()
    {
        return @"<$iface>";
    }

    public static void exec( string app, string iface, string arg, string arg2 = "" )
    {
        string[] argv = new string[4];
        argv[0] = app;
        argv[1] = iface;
        argv[2] = arg;
        argv[3] = arg2;

        Pid child_pid;
        int input_fd;
        int output_fd;
        int error_fd;
        try {
            Process.spawn_async_with_pipes(
            ".",
            argv, //argv
            null,   // environment
            SpawnFlags.SEARCH_PATH,
            null,   // child_setup
            out child_pid,
            out input_fd,
            out output_fd,
            out error_fd);
        }
        catch (Error e) {
            FsoFramework.theLogger.error ( @"Could not call $app $iface $arg!" );
        }
    }

    public bool getPower()
    {
        return power;
    }

    public void setPower( bool on )
    {
        string arg;
        power = on;
        if (on)
            arg = "up";
        else
            arg = "down";
        exec("/sbin/ifconfig", iface, arg);
        if (on) exec("/sbin/iwconfig", iface, "power", "on"); // TODO: add config option for that
    }

    //
    // DBUS API (org.freesmartphone.Device.PowerControl)
    //
    public async bool get_power() throws DBusError, IOError
    {
        return getPower();
    }

    public async void set_power( bool on ) throws DBusError, IOError
    {
        setPower( on );
    }

}

/**
 * Implementation of org.freesmartphone.Resource for the Proximity Resource
 **/
class WiFiResource : FsoFramework.AbstractDBusResource
{
    internal bool on;

    public WiFiResource( FsoFramework.Subsystem subsystem )
    {
        base( "WiFi", subsystem );
    }

    public override async void enableResource()
    {
        if (on)
            return;
        assert( logger.debug( "Enabling..." ) );
        instance.set_power( true );
        on = true;
    }

    public override async void disableResource()
    {
        if (!on)
            return;
        assert( logger.debug( "Disabling..." ) );
        instance.set_power( false );
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

static string iface;
PowerControl.Ifconfig instance;
PowerControl.WiFiResource resource;

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    var config = FsoFramework.theConfig;
    iface = config.stringValue( "fsodevice.powercontrol_ifconfig", "interface", "wlan0" );
    instance = new PowerControl.Ifconfig( subsystem, iface );
    resource = new PowerControl.WiFiResource( subsystem );
    instance.set_power( false );
    return "fsodevice.powercontrol_ifconfig";
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsodevice.powercontrol_ifconfig fso_register_function()" );
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
