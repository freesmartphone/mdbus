/**
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

class DBusService.Device : FsoFramework.AbstractObject
{
    const string MODULE_NAME = "fsotdl.provider_gps";

    FsoFramework.Subsystem subsystem;
    private static FsoGps.Receiver receiver;
    public static Type receiverclass;

    public Device( FsoFramework.Subsystem subsystem )
    {
        var locationtype = config.stringValue( MODULE_NAME, "provider_type", "DummyReceiver" );
        if ( locationtype == "DummyReceiver" )
        {
            logger.critical( "receiver_type not specified and DummyReceiver not implemented yet" );
            return;
        }
        string typename;

        switch ( locationtype )
        {
            case "nmea":
                typename = "NmeaReceiver";
                break;
            default:
                logger.critical( "Invalid receiver_type '%s'; corresponding receiver plugin loaded?".printf( locationtype ) );
                return;
        }

        receiverclass = Type.from_name( typename );
        if ( receiverclass == Type.INVALID  )
        {
            logger.warning( "Can't find receiver for receiver_type = '%s'".printf( locationtype ) );
            return;
        }

        /*
        subsystem.registerServiceName( FsoFramework.GPS.ServiceDBusName );
        subsystem.registerServiceObject( FsoFramework.GPS.ServiceDBusName, FsoFramework.GPS.DeviceServicePath, this );
        */

        receiver = (FsoGps.Receiver) Object.new( receiverclass );
        receiver.parent = this;

        logger.info( "Ready. Configured for receiver '%s'".printf( locationtype ) );
    }

    public override string repr()
    {
        return "<DBusService>";
    }

    public void enable()
    {
        if ( !receiver.open() )
            logger.error( "Can't open receiver" );
        else
            logger.info( "GPS receiver opened successfully" );
    }

    public void disable()
    {
        receiver.close();
        logger.info( "GPS receiver closed successfully" );
    }

    public void suspend()
    {
        logger.critical( "Not yet implemented" );
    }

    public void resume()
    {
        logger.critical( "Not yet implemented" );
    }
}

public class DBusService.Resource : FsoFramework.AbstractDBusResource
{
    public Resource( FsoFramework.Subsystem subsystem )
    {
        base( "GPS", subsystem );
    }

    public override async void enableResource()
    {
        logger.debug( "Enabling GPS resource..." );
        device.enable();
    }

    public override async void disableResource()
    {
        logger.debug( "Disabling GPS resource..." );
        device.disable();
    }

    public override async void suspendResource()
    {
        logger.debug( "Suspending GPS resource..." );
        device.suspend();
    }

    public override async void resumeResource()
    {
        logger.debug( "Resuming GPS resource..." );
        device.resume();
    }
}

DBusService.Device device;
DBusService.Resource resource;

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    device = new DBusService.Device( subsystem );
    if ( DBusService.Device.receiverclass != Type.INVALID )
    {
        resource = new DBusService.Resource( subsystem );
    }
    return DBusService.Device.MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    debug( "provider_gps fso_register_function" );
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
