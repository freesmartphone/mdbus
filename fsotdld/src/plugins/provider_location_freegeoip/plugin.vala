/*
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

class Location.FreeGeoIp : FsoTdl.AbstractLocationProvider
{
    internal const string MODULE_NAME = "fsotdl.provider_location_freegeoip";

    // alternatively we could use http://ipdetect.dnspark.com/
    private const string MYIP_SERVER_NAME = "checkip.dyndns.org";
    // alternatively we could use http://ipinfodb.com/ip_query.php?timezone=true
    private const string SERVER_NAME = "freegeoip.net";
    private const string QUERY_URI = "/csv/%s";

    FsoFramework.Subsystem subsystem;
    string servername;
    string queryuri;

    construct
    {
        servername = SERVER_NAME;
        queryuri = QUERY_URI.printf( "85.180.141.230" );
        logger.info( "Ready." );
    }

    public override string repr()
    {
        return "<>";
    }

    //
    // private API
    //
    private async void asyncTrigger()
    {
        var myip = yield FsoFramework.Network.textForUri( MYIP_SERVER_NAME );
        if ( myip == null )
        {
            logger.warning( @"Can't gather my IP from $MYIP_SERVER_NAME" );
            return;
        }

        Regex regex;
        try
        {
            regex = new Regex( "Current IP Address: (?P<ip>[0-9][0-9]?[0-9]?[0-9]?.[0-9][0-9]?[0-9]?[0-9]?.[0-9][0-9]?[0-9]?[0-9]?.[0-9][0-9]?[0-9]?[0-9]?)" );
        }
        catch ( RegexError e )
        {
            assert_not_reached();
        }

        MatchInfo mi;
        regex.match( myip[0], 0, out mi );
        if ( mi == null )
        {
            logger.warning( @"Can't parse $(myip[0])" );
            return;
        }
        var ip = mi.fetch_named( "ip" );
        assert( logger.debug( @"My IP seems to be $ip" ) );

        var result = yield FsoFramework.Network.textForUri( servername, queryuri.printf( ip ) );
        if ( ! ( result != null && result.length > 0 && !result[0].has_prefix( "<html>" ) ) )
        {
            logger.warning( @"Could not get information for IP $ip from $servername" );
            return;
        }

        // Usual answer retrieved from this server is something like:
        // 85.180.141.230,DE,Germany,05,Hessen,Frankfurt Am Main,,50.1167,8.6833,

        var components = result[0].split( "," );

        var map = new HashTable<string,Variant>( str_hash, str_equal );
        if ( components.length > 1 )
            map.insert( "countrycode", components[1] );
        if ( components.length > 2 )
            map.insert( "countryname", components[2] );
        if ( components.length > 3 )
            map.insert( "regioncode", components[3] );
        if ( components.length > 4 )
            map.insert( "regionname", components[4] );
        if ( components.length > 5 )
            map.insert( "city", components[5] );
        if ( components.length > 6 )
            map.insert( "zipcode", components[6] );
        if ( components.length > 7 )
        {
            map.insert( "latitude", components[7].to_double() );
            map.insert( "accuracy", accuracy() );
        }
        if ( components.length > 8 )
            map.insert( "longitude", components[8].to_double() );
        if ( components.length > 9 )
            map.insert( "gmt", components[9] );
        if ( components.length > 10 )
            map.insert( "dst", components[10] );

        this.location( this, map );
    }

    //
    // FsoTdl.AbstractLocationProvider
    //
    public override void start()
    {
        asyncTrigger();
    }

    public override void stop()
    {
        // ...
    }
    public override uint accuracy()
    {
        return 1000 * 100;
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
    return Location.FreeGeoIp.MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsotdl.provider_location_freegeoip fso_register_function" );
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
