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

public delegate void StringInVoidOutFunc( string str );

namespace Nmea {
    const string MODULE_NAME = "fsotdl.source_gps_nmea";
    const string CHANNEL_NAME = "NMEA";
}

class Nmea.Receiver : FsoGps.AbstractReceiver
{
    private Nmea.Protocol protocol;

    public override string repr()
    {
        return "<>";
    }

    protected override void createChannels()
    {
        var transport = FsoFramework.Transport.create( receiver_transport, receiver_port, receiver_speed );
        var parser = new FsoFramework.LineByLineParser();
        var chan = new FsoGps.Channel( CHANNEL_NAME, transport, parser );

        protocol = new Nmea.Protocol( this );
    }

    public override void processUnsolicitedResponse( string prefix, string righthandside, string? pdu = null )
    {
        message( @"NMEA DATUM: $righthandside" );
        assert( protocol != null );
        if ( righthandside.length > 6 )
        {
            protocol.feed( righthandside );
        }
    }
}

public class Nmea.DelegateAndRegex
{
    public StringInVoidOutFunc func;
    public GLib.Regex re;

    public DelegateAndRegex( owned StringInVoidOutFunc func, owned GLib.Regex re )
    {
        this.func = func;
        this.re = re;
    }
}

class Nmea.Protocol : Object
{
    private Gee.HashMap<string,Nmea.DelegateAndRegex> delegates;
    private GLib.MatchInfo mi;
    private FsoGps.AbstractReceiver receiver;

    private bool match( GLib.Regex re, string str )
    {
        bool match;
        match = re.match( str, 0, out mi );
        return ( match ) ? mi != null : false;
    }

    private T to<T>( string name )
    {
        var res = mi.fetch_named( name );

        if ( typeof(T) == typeof(int) )
        {
            message( "%s: %d", name, res.to_int() );
            return ( res == null ) ? 0 : res.to_int();
        }
        else if ( typeof(T) == typeof(string) )
        {
            return ( res == null ) ? "" : res;
        }
        /* not possible due to bug in vala
        else if ( typeof(T) == typeof(double) )
        {
            return ( res == null ) ? 0.0 : res.to_double();
        }
        */
        else
        {
            assert_not_reached();
        }
    }

    public void onGpzda( string datum )
    {
        GLib.Time t = {};
        t.hour = to<int>( "hour" );
        t.minute = to<int>( "minute" );
        t.second = to<int>( "second" );
        t.day = to<int>( "day" );
        t.month = to<int>( "month" ) - 1;
        t.year = to<int>( "year" ) - 1900;

        var zoneh = to<int>( "zoneh" );
        var zonem = to<int>( "zonem" );

        var epoch = Linux.timegm( t );
#if DEBUG
        debug( "GPZDA reports %d".printf( (int)epoch ) );
#endif
    }

    public void onGpgsv( string datum )
    {
        int numsats = to<int>( "numsats" );
        debug( @"GPGSV reports $numsats sats in view" );
    }

    public void onGprmc( string datum )
    {
        bool valid = ( to<string>( "valid" ) == "A" );
        if ( !valid )
        {
            return;
        }

        var report = new GLib.HashTable<string,Value?>( str_hash, str_equal );

        double lat = to<int>( "latdd" ) + to<string>( "lat" ).to_double() / 60;
        double lon = to<int>( "londd" ) + to<string>( "lon" ).to_double() / 60;

        debug( @"GPRMC reports location %.6f N + %.6f E".printf( lat, lon ) );

        report.insert( "lat", lat );
        report.insert( "lon", lon );

        receiver.location( receiver, report );
    }

    //
    // public API
    //

    public Protocol( FsoGps.AbstractReceiver receiver )
    {
        this.receiver = receiver;
        delegates = new Gee.HashMap<string,Nmea.DelegateAndRegex>();

        // $GPZDA,204629.00,30,11,2009,00,00*65
        var reGpzda = /\$GPZDA,(?P<hour>[0-2][0-9])(?P<minute>[0-9][0-9])(?P<second>[0-9][0-9])\.[0-9][0-9],(?P<day>[0-3][0-9]),(?P<month>[01][0-9]),(?P<year>20[0-9][0-9]),(?P<zoneh>[01][0-9]),(?P<zonem>[01][0-9])/;
        delegates["GPZDA"] = new Nmea.DelegateAndRegex( onGpzda, (owned) reGpzda );

        var reGpgsv = /\$GPGSV,(?P<seqtotal>[0-9]),(?P<seqthis>[0-9]),(?P<numsats>[0-9]*),(?P<sat1id>[0-9]*),(?P<sat1ev>[-0-9]*),(?P<sat1az>[0-9]*),(?P<sat1qual>[0-9]*)(?:,(?P<sat2id>[0-9]*),(?P<sat2ev>[-0-9]*),(?P<sat2az>[0-9]*),(?P<sat2qual>[0-9]*),(?:(?P<sat3id>[0-9]*),(?P<sat3ev>[-0-9]*),(?P<sat3az>[0-9]*),(?P<sat3qual>[0-9]*),(?P<sat4id>[0-9]*),(?P<sat4ev>[-0-9]*)(?:,(?P<sat4az>[0-9]*),(?P<sat4qual>[0-9]*))?)?)?/;
        delegates["GPGSV"] = new Nmea.DelegateAndRegex( onGpgsv, (owned) reGpgsv );

        var reGprmc = /\$GPRMC,(?P<hour>[0-9][0-9])(?P<minute>[0-9][0-9])(?P<second>[0-9][0-9])(?:.00)?,(?P<valid>[AV]),(?P<latdd>[0-9][0-9])(?P<lat>[0-9.]*),(?P<latsign>[NS])?,(?P<londd>[0-9][0-9][0-9])(?P<lon>[0-9.]*),(?P<lonsign>[WE])?,(?P<velocity>[0-9.]*),(?P<angle>[0-9.]*),(?P<day>[0-3][0-9])?(?P<month>[01][0-9])?(?P<year>[0-9][0-9])?,(?P<misangle>[0-9.]*),(?P<misanglesign>[WE]?)?,(?P<type>[ADENS])/;
        delegates["GPRMC"] = new Nmea.DelegateAndRegex( onGprmc, (owned) reGprmc );
    }

    public void feed( string datum )
    {
        var prefix = datum.substring( 1, 5 );
        var holder = delegates[prefix];
        if ( holder == null )
        {
            debug( @"Unhandled NMEA datum $prefix; fix me?" );
            return;
        }
        if ( !match( holder.re, datum ) )
        {
            debug( @"NMEA datum $datum does not match $(holder.re.get_pattern()); fix me?" );
            return;
        }
        assert( holder.func != null );
        holder.func( datum );
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
    FsoFramework.theLogger.debug( "fsotdl.provider_gps_nmea fso_factory_function" );
    return Nmea.MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsotdl.provider_gps_nmea fso_register_function" );
    // do not remove this function
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
