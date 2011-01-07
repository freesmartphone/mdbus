/*
 * Copyright (C) 2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

class Location.Gpsd : FsoTdl.AbstractLocationProvider
{
    internal const string MODULE_NAME = "fsotdl.provider_location_gpsd";

    FsoFramework.Subsystem subsystem;
    string servername;
    string queryuri;

    Gps.Device gps;

    construct
    {
        if ( gps.open() == 0 )
        {
            logger.debug( "GPS opened" );
        }
        else
        {
            logger.critical( "Can't open GPS: %s".printf( Gps.errstr( errno ) ) );
        }

        Timeout.add_seconds( 3, onTimeout );

        logger.info( "Ready." );
    }

    public override string repr()
    {
        return "<>";
    }

    private bool onTimeout()
    {
        if ( gps.waiting() )
        {
            logger.debug( "GPS data waiting... reading" );
            var bytesRead = gps.read();
            logger.debug( @"Read $bytesRead from GPS" );
        }
        else
        {
            logger.debug( "No gps data waiting" );
        }
        return true;
    }

    //
    // private API
    //
    private async void asyncTrigger()
    {
        /*

        var map = new HashTable<string,Variant>( str_hash, str_equal );
        map.insert( "countrycode", components[2] );
        map.insert( "countryname", components[3] );
        map.insert( "regioncode", components[4] );
        map.insert( "regionname", components[5] );
        map.insert( "city", components[6] );
        map.insert( "zipcode", components[7] );
        map.insert( "latitude", components[8].to_double() );
        map.insert( "longitude", components[9].to_double() );
        map.insert( "gmt", components[10] );
        map.insert( "dst", components[11] );
        this.location( this, map );
        */
    }

    //
    // FsoTdl.AbstractLocationProvider
    //
    public override void trigger()
    {
        asyncTrigger();
    }

    public override uint accuracy()
    {
        return 100 * 1000;
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
    return Location.Gpsd.MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsotdl.provider_location_gpsd fso_register_function" );
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
