/*
 * Copyright (C) 2012 Rico Rommel <rico@bierrommel.de>
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
using FsoTime;

/**
 * @class Source.Gpsddbus
 **/
class Source.Gpsddbus : FsoTime.AbstractSource
{
    private uint sig_id;

    private struct Fix
    {
        public double time;
        public int32 mode;
        public double ept;
        public double latitude;
        public double longitude;
        public double eph;
        public double altitude;
        public double epv;
        public double direction;
        public double epd;
        public double speed;
        public double eps;
        public double climb;
        public double epc;
        public string device;
    }

    private Fix f;
    private double old_time;
    private double updateinterval;
    private DBusConnection conn;

    public const string MODULE_NAME = "fsotdl.source_gpsddbus";

    construct
    {
        f = Fix();
        old_time = 0;
        try
        {
            conn = Bus.get_sync( BusType.SYSTEM );
        }
        catch (IOError e)
        {
            logger.error( "Cannot connect to dbus system bus" );
            return;
        }

        sig_id = conn.signal_subscribe( null, "org.gpsd", "fix", "/org/gpsd", null, DBusSignalFlags.NONE, onFix );
        updateinterval = (double) updateInterval();
    }

    public override string repr()
    {
        return "<>";
    }

    public override void triggerQuery() { }

    private void onFix( DBusConnection connection, string sender_name, string object_path, string interface_name, string signal_name, Variant parameters )
    {
        parameters.get( "(didddddddddddds)", out f.time, out f.mode, out f.ept, out f.latitude, out f.longitude,
                                             out f.eph, out f.altitude, out f.epv, out f.direction, out f.epd,
                                             out f.speed, out f.eps, out f.climb, out f.epc, out f.device );

        if ( f.mode == 3 )
        {
            if ( f.time > (old_time + updateinterval) )
            {
                logger.debug( "received fix: mode: " +  f.mode.to_string() + " time: " + f.time.to_string()  );
                old_time = f.time;
                this.reportTime( (int) f.time, this );
                this.reportLocation( f.latitude, f.longitude, (int) f.altitude, this );
            }

        }
    }

    private int updateInterval() 
    {
        var config = FsoFramework.theConfig;
        int tmp_update_interval;
        tmp_update_interval = config.intValue(MODULE_NAME, "update_interval", 60 );
        assert( logger.debug( "update interval is %s seconds".printf( tmp_update_interval.to_string() ) ) );
        return tmp_update_interval;
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
    FsoFramework.theLogger.debug( "fsotdl.source_gpsddbus fso_factory_function" );
    return Source.Gpsddbus.MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsotdl.source_gpsddbus fso_register_function" );
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
