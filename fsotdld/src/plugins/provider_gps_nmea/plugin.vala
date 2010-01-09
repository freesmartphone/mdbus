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

public delegate void StringInVoidOutFunc( string str );

namespace Nmea {
    const string MODULE_NAME = "fsotldl.source_gps_nmea";
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

        protocol = new Nmea.Protocol();
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

        debug( "GPZDA reports %d".printf( (int)epoch ) );
    }

    //
    // public API
    //

    public Protocol()
    {
        delegates = new Gee.HashMap<string,Nmea.DelegateAndRegex>();

        // $GPZDA,204629.00,30,11,2009,00,00*65
        var reGpzda = new Regex( """\$GPZDA,(?P<hour>[0-2][0-4])(?P<minute>[0-9][0-9])(?P<second>[0-9][0-9])\.[0-9][0-9],(?P<day>[0-3][0-9]),(?P<month>[01][0-9]),(?P<year>20[0-9][0-9]),(?P<zoneh>[01][0-9]),(?P<zonem>[01][0-9])""" );
        delegates["GPZDA"] = new Nmea.DelegateAndRegex( onGpzda, (owned) reGpzda );

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
    debug( "fsoltdl.provider_gps_nmea fso_factory_function" );
    return Nmea.MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    debug( "fsotdl.source_gps fso_register_function" );
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
