/*
 * Copyright (C) 2011-2012 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

    private FsoFramework.Subsystem subsystem;
    private uint watch = 0;
    private Gps.Device gps;

    construct
    {
        logger.info( "Ready." );
    }

    public override string repr()
    {
        return "<>";
    }

    //
    // private API
    //
    private bool onTimeout()
    {
        if ( gps.waiting( 10000 ) )
        {
            assert( logger.debug( "GPS data waiting... reading" ) );
            var bytesRead = gps.read();
            var device = gps.dev.path;
            var driver = gps.dev.driver;
            var subtype = gps.dev.subtype;
            assert( logger.debug( @"Read $bytesRead from GPS [$device:$driver:$subtype], LON:$(gps.fix.latitude), LAT:$(gps.fix.longitude)" ) );
            if ( ! ( gps.fix.latitude.is_nan() || gps.fix.longitude.is_nan() ) )
            {
                var map = new HashTable<string,Variant>( str_hash, str_equal );
                map.insert( "latitude", gps.fix.latitude );
                map.insert( "longitude", gps.fix.longitude );
                map.insert( "gmt", gps.fix.time.to_string() );
                this.location( this, map );
            }
        }
        else
        {
            assert( logger.debug( "No gps data waiting" ) );
        }
        return true;
    }

    //
    // FsoTdl.AbstractLocationProvider
    //
    public override void start()
    {
        if ( gps.open() == 0 )
        {
            assert( logger.debug( "GPS opened successfully" ) );
            gps.stream( Gps.StreamingPolicy.ENABLE );
            watch = Timeout.add_seconds( 3, onTimeout );
        }
        else
        {
            logger.error( "Can't open GPS: %s".printf( Gps.errstr( errno ) ) );
        }
    }

    public override void stop()
    {
        if ( watch > 0 )
        {
            Source.remove( watch );
            gps.close();
        }
    }

    public override uint accuracy()
    {
        return 20;
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

// vim:ts=4:sw=4:expandtab
