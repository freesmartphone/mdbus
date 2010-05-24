/*
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

class Location.FreeGeoIp : FsoTdl.AbstractLocationProvider
{
    internal const string MODULE_NAME = "fsotdl.provider_location_freegeoip";

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
            logger.warning( "Can't gather my IP from $MYIP_SERVER_NAME" );
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
        if ( result == null || result.length != 3 || result[2].has_prefix( "False" ) )
        {
            logger.warning( @"Could not get information for IP $ip from $servername" );
            return;
        }

        // Usual answer retrieved from this server is something like:
        // 52
        // True,85.180.141.230,DE,Germany,05,Hessen,Frankfurt Am Main,,50.1167,8.6833,1.0,2.0
        // 0

        var components = result[1].split( "," );
        var map = new HashTable<string,Value?>( str_hash, str_equal );
        map.insert( "code", components[2] );
        map.insert( "country", components[3] );
        map.insert( "region", components[4] );
        map.insert( "city", components[5] );
        map.insert( "zip", components[6] );
        map.insert( "lat", components[7] );
        map.insert( "lon", components[8] );
        map.insert( "gmt", components[9] );
        map.insert( "dst", components[10] );
        this.location( this, map );
    }

    //
    // FsoTdl.AbstractLocationProvider
    //
    public override void trigger()
    {
        asyncTrigger();
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
