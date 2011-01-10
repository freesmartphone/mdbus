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

class Location.CellidWifi : FsoTdl.AbstractLocationProvider
{
    internal const string MODULE_NAME = "fsotdl.provider_location_cellidwifi";

    private const string SERVER_NAME = "https://www.google.com";
    private const string QUERY_URI = "/loc/json";

    private FsoFramework.Subsystem subsystem;
    private string servername;
    private string queryuri;

    private FreeSmartphone.GSM.Network gsmnetwork;
    private WpaDBusIface wpaiface;

    construct
    {
        Idle.add( () => { onIdle(); return false; } );
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
    private async void onIdle()
    {
        try
        {
            gsmnetwork = yield Bus.get_proxy<FreeSmartphone.GSM.Network>( BusType.SYSTEM, FsoFramework.GSM.ServiceDBusName, FsoFramework.GSM.DeviceServicePath, DBusProxyFlags.DO_NOT_AUTO_START );
        }
        catch ( Error e1 )
        {
        }

        try
        {
            wpaiface = yield Bus.get_proxy<WpaDBusIface>( BusType.SYSTEM, "fi.epitest.hostap.WPASupplicant", "/fi/epitest/hostap/WPASupplicant/Interfaces/1", DBusProxyFlags.DO_NOT_AUTO_START );
        }
        catch ( Error e2 )
        {
        }
    }

    private async Gee.HashMap<string,int> gatherAccessPoints()
    {
        var aptable = new Gee.HashMap<string,int>( str_hash, str_equal );
        ulong handle = 0;

        try
        {
            handle = wpaiface.ScanResultsAvailable.connect( () => {
                wpaiface.disconnect( handle );
                logger.debug( @"Scan results available" );
                gatherAccessPoints.callback();
            } );
            yield wpaiface.scan();

            yield; // wait for signal to arrive

            var aps = yield wpaiface.scanResults();
            logger.debug( @"Got $(aps.length) scan results" );
            foreach ( unowned GLib.ObjectPath path in aps )
            {
                var bssid = Path.get_basename( (string)path );
                aptable[bssid] = 8;
                logger.debug( @"Found AP with BSSID '%s'".printf( (string)path ) );
            }
        }
        catch ( Error e )
        {
            logger.error( @"Could not gather access points: $(e.message)" );
        }
        return aptable;
    }

    private async void asyncTrigger()
    {
        GLib.HashTable<string,Variant> hashtable = null;
        Gee.HashMap<string,int> aptable = null;
        bool haveGsmData = false;
        bool haveWifiData = false;

        // gather current serving cell params
        try
        {
            hashtable = yield gsmnetwork.get_status();
            haveGsmData = true;
        }
        catch ( Error e1 )
        {
            logger.info( @"Could not get status from GSM: $(e1.message)" );
        }

        // gather access points in vincinity
        try
        {
            aptable = yield gatherAccessPoints();
            haveWifiData = true;
        }
        catch ( Error e3 )
        {
            logger.info( @"Could not get status from WiFi: $(e3.message)" );
        }

        if ( !haveGsmData && !haveWifiData )
        {
            logger.error( "Neither GSM nor WiFi data available. Can't request location" );
            return;
        }

        var jsonrequeststr = """
{
    "version": "1.1.0",
    "host": "perdu.com",
    "request_address": true,
    "address_language": "en_GB"
""";

        if ( haveGsmData )
        {
            string slac = (string) hashtable.lookup( "lac" ) ?? "unknown";
            string scid = (string) hashtable.lookup( "cid" ) ?? "unknown";
            int lac = 0;
            int cid = 0;
            slac.scanf( "%X", &lac );
            scid.scanf( "%X", &cid );
            string code = (string) hashtable.lookup( "code" ) ?? "000000";
            string mcc = code[0:3];
            string mnc = code[3:code.length];

            jsonrequeststr += """
    , "cell_towers": [ {"location_area_code": "%d",
                    "mobile_network_code": "%s",
                    "cell_id": "%d",
                    "mobile_country_code": "%s"}]
""".printf( lac, mnc, cid, mcc );

        }

        if ( haveWifiData )
        {
            var wifitowers = "";

            foreach ( var bssid in aptable.keys )
            {
                wifitowers += """{ "mac_address": "%s", "signal_strength": %d, "age": 0 },""".printf( bssid, aptable[bssid] );
            }

            jsonrequeststr += """, "wifi_towers": [ %s ]""".printf( wifitowers[0:wifitowers.length-1] );
        }

        jsonrequeststr += "}";

#if DEBUG
        debug( "jsonrequest is '%s'", jsonrequeststr );
#endif

        var jsonrequest = new uint8[jsonrequeststr.length];
        Memory.copy( jsonrequest, jsonrequeststr, jsonrequeststr.length );

        var session = new Soup.SessionSync();
        var message = new Soup.Message( "POST", SERVER_NAME + QUERY_URI );
        message.set_request( "application/json", Soup.MemoryUse.COPY, jsonrequest );
        session.send_message( message );
        logger.debug( "Response is %s".printf( (string)message.response_body.data ) );

        var parser = new Json.Parser();
        try
        {
            parser.load_from_data( (string)message.response_body.flatten().data, -1 );
        }
        catch ( Error e2 )
        {
            logger.error( @"Invalid format: $(e2.message)" );
            return;
        }

        var root = parser.get_root().get_object();

        if ( !root.has_member( "location" ) )
        {
            logger.error( "Invalid response: No 'location' in root object" );
            return;
        }

        var location = root.get_object_member( "location" );
        var map = new HashTable<string,Variant>( str_hash, str_equal );
        map.insert( "latitude", location.get_double_member( "latitude" ) );
        map.insert( "longitude", location.get_double_member( "longitude" ) );

        if ( location.has_member( "address" ) )
        {
            var address = location.get_object_member( "address" );
            map.insert( "countryycode", address.get_string_member( "country_code" ) );
            map.insert( "countryname", address.get_string_member( "country" ) );
            map.insert( "regionname", address.get_string_member( "region" ) );
            map.insert( "city", address.get_string_member( "city" ) );
            map.insert( "zipcode", address.get_string_member( "postal_code" ) );
            map.insert( "street", address.get_string_member( "street" ) );
            map.insert( "streetnumber", address.get_string_member( "street_number" ) );
        }
        //FIXME: accuracy?

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
        return 1000;
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
    return Location.CellidWifi.MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsotdl.provider_location_cellidwifi fso_register_function" );
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
