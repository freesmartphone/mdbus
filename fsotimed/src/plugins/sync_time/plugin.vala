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

namespace DBusService {
    const string MODULE_NAME = "fsotime.sync_time";
}

class DBusService.Device :
    FsoFramework.AbstractObject
{
    FsoFramework.Subsystem subsystem;
    private static FsoTime.Source Source;
    public static Type Sourceclass;

    public Device( FsoFramework.Subsystem subsystem )
    {
        var gpstype = config.stringValue( "fsotime", "Source_type", "DummySource" );
        if ( gpstype == "DummySource" )
        {
            logger.critical( "Source_type not specified and DummySource not implemented yet" );
            return;
        }
        string typename;

        switch ( gpstype )
        {
            case "nmea":
                typename = "NmeaSource";
                break;
            default:
                logger.critical( "Invalid Source_type '%s'; corresponding Source plugin loaded?".printf( gpstype ) );
                return;
        }

        Sourceclass = Type.from_name( typename );
        if ( Sourceclass == Type.INVALID  )
        {
            logger.warning( "Can't find Source for Source_type = '%s'".printf( gpstype ) );
            return;
        }

        /*
        subsystem.registerServiceName( FsoFramework.GPS.ServiceDBusName );
        subsystem.registerServiceObject( FsoFramework.GPS.ServiceDBusName, FsoFramework.GPS.DeviceServicePath, this );
        */

        //logger.info( "Ready. Configured for Source '%s'".printf( gpstype ) );
    }

    public override string repr()
    {
        return "<DBusService>";
    }
}

/*
DBusService.Device device;
DBusService.Resource resource;
*/

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    /*
    sycndevice = new DBusService.Device( subsystem );
    if ( DBusService.Device.Sourceclass != Type.INVALID )
    {
        resource = new DBusService.Resource( subsystem );
    }
    */
    return null;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    debug( "fsotime.sync_time fso_register_function" );
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
