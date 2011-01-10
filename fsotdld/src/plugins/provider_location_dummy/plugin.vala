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

class Location.Dummy : FsoTdl.AbstractLocationProvider
{
    internal const string MODULE_NAME = "fsotdl.provider_location_dummy";

    FsoFramework.Subsystem subsystem;
    string servername;
    string queryuri;

    uint watch = 0;

    construct
    {
        logger.info( "Ready." );
    }

    public override string repr()
    {
        return "<:)>";
    }

    //
    // private API
    //
    private async void asyncTrigger()
    {
        var map = new HashTable<string,Variant>( str_hash, str_equal );
        map.insert( "latitude", config.doubleValue( MODULE_NAME, "latitude", 50.0 ) );
        map.insert( "longitude", config.doubleValue( MODULE_NAME, "longitude", 8.0 ) );
        this.location( this, map );
    }

    //
    // FsoTdl.AbstractLocationProvider
    //
    public override void start()
    {
        var frequency = config.intValue( MODULE_NAME, "frequency", 5 );
        watch = Timeout.add_seconds( frequency, () => {
            asyncTrigger();
            return true;
        } );
    }

    public override void stop()
    {
        if ( watch > 0 )
        {
            Source.remove( watch );
        }
    }
    public override uint accuracy()
    {
        return config.intValue( MODULE_NAME, "accuracy", 100 );
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
    return Location.Dummy.MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsotdl.provider_location_dummy fso_register_function" );
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
