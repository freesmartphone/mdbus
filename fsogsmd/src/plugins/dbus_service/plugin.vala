/*
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 */

using GLib;

public class FsoGsm.DeviceServiceManager : FsoGsm.AbstractServiceManager
{
    public DeviceServiceManager( FsoFramework.Subsystem subsystem )
    {
        base( subsystem, FsoFramework.GSM.ServiceDBusName, FsoFramework.GSM.DeviceServicePath );

        base.registerService<FreeSmartphone.Info>( new FsoGsm.InfoService() );
        base.registerService<FreeSmartphone.Device.RealtimeClock>( new FsoGsm.DeviceRtcService() );
        base.registerService<FreeSmartphone.Device.PowerSupply>( new FsoGsm.DevicePowerSupplyService() );
        base.registerService<FreeSmartphone.GSM.Device>( new FsoGsm.GsmDeviceService() );
        base.registerService<FreeSmartphone.GSM.Debug>( new FsoGsm.GsmDebugService() );
        base.registerService<FreeSmartphone.GSM.Call>(new FsoGsm.GsmCallService() );
        base.registerService<FreeSmartphone.GSM.CB>( new FsoGsm.GsmCbService() );
        base.registerService<FreeSmartphone.GSM.HZ>( new FsoGsm.GsmHzService() );
        base.registerService<FreeSmartphone.GSM.Monitor>( new FsoGsm.GsmMonitorService() );
        base.registerService<FreeSmartphone.GSM.Network>( new FsoGsm.GsmNetworkService() );
        base.registerService<FreeSmartphone.GSM.PDP>( new FsoGsm.GsmPdpService() );
        base.registerService<FreeSmartphone.GSM.SIM>( new FsoGsm.GsmSimService() );
        base.registerService<FreeSmartphone.GSM.SMS>( new FsoGsm.GsmSmsService() );
        base.registerService<FreeSmartphone.GSM.VoiceMail>( new FsoGsm.GsmVoiceMailService() );
    }
}

namespace DBusService
{
    const string MODULE_NAME = "fsogsm.dbus_service";
    FsoGsm.DeviceServiceManager deviceServiceManager = null;
}

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    /*
    if ( DBusService.Device.modemclass != Type.INVALID )
        resource = new DBusService.Resource( subsystem );
    */

    DBusService.deviceServiceManager = new FsoGsm.DeviceServiceManager( subsystem );

    return DBusService.MODULE_NAME;
}

/**
 * This function gets called on subsystem shutdown time.
 **/
public static void fso_shutdown_function() throws Error
{
#if DEBUG
    debug( "SHUTDOWN ENTER" );
#endif
    running = true;
    async_helper();
    while ( running )
    {
        GLib.MainContext.default().iteration( true );
    }
#if DEBUG
    debug( "SHUTDOWN LEAVE" );
#endif
}

static bool running;
internal async void async_helper()
{
#if DEBUG
    debug( "ASYNC_HELPER ENTER" );
#endif
    // yield resource.disableResource();
    running = false;
#if DEBUG
    debug( "ASYNC_HELPER_DONE" );
#endif
}

/**
 * Module init function, DON'T REMOVE THIS!
 **/
[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsogsm.dbus_service fso_register_function" );
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
