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

namespace SyncTime {
    const string MODULE_NAME = "fsotdl.sync_time";
    // contains the timezone as verbose string, e.g. 'Europe/Berlin'
    const string TIMEZONE_FILE_DEFAULT = "/etc/timezone";
    // contains the timezone data as found in /usr/share/zoneinfo
    const string LOCALTIME_FILE_DEFAULT = "/etc/localtime";
    // contains all the timezone files
    const string ZONEINFO_DIR_DEFAULT = "/usr/share/zoneinfo";
}

class SyncTime.Service : FsoFramework.AbstractObject
{
    FsoFramework.Subsystem subsystem;
    private Gee.HashMap<string,FsoTime.Source> sources;
    private string timezone_file;
    private string localtime_file;
    private string zoneinfo_dir;
    private bool try_adjtime;

    public Service( FsoFramework.Subsystem subsystem )
    {
        sources = new Gee.HashMap<string,FsoTime.Source>();
        var sourcenames = config.stringListValue( MODULE_NAME, "sources", {} );
        foreach ( var source in sourcenames )
        {
            addSource( source );
        }
        timezone_file = config.stringValue( MODULE_NAME, "timezone_file", TIMEZONE_FILE_DEFAULT );
        localtime_file = config.stringValue( MODULE_NAME, "localtime_file", LOCALTIME_FILE_DEFAULT );
        zoneinfo_dir = config.stringValue( MODULE_NAME, "zoneinfo_dir", ZONEINFO_DIR_DEFAULT );
        try_adjtime = config.boolValue( MODULE_NAME, "try_adjtime_before_settime", false );
        logger.debug( @"try_adjtime_before_settime = $try_adjtime" );
        logger.info( @"Ready. Configured for $(sources.size) sources." );
    }

    public void addSource( string name )
    {
        var typename = "unknown";

        switch ( name )
        {
            case "ntp":
                typename = "SourceNtp";
                break;
            case "gps":
                typename = "SourceGps";
                break;
            case "gsm":
                typename = "SourceGsm";
                break;
            case "dummy":
                typename = "SourceDummy";
                break;
            default:
                logger.warning( @"Unknown source $name - Ignoring" );
                return;
        }
        var sourceclass = Type.from_name( typename );
        if ( sourceclass == Type.INVALID  )
        {
            logger.warning( @"Can't find source $name (type=$typename) - plugin loaded?" );
            return;
        }
        sources[name] = (FsoTime.Source) Object.new( sourceclass );
        logger.info( @"Added source $name ($typename)" );
        sources[name].reportTime.connect( onTimeReport );
        sources[name].reportZone.connect( onZoneReport );
        sources[name].reportLocation.connect( onLocationReport );
    }

    public override string repr()
    {
        return @"<$(sources.size)>";
    }

    public void onTimeReport( int since_epoch, FsoTime.Source source )
    {
        time_t now = time_t();
        int offset = since_epoch-(int)now;

        assert( logger.debug( "%s reports %u, we think %u, offset = %d".printf( ((FsoFramework.AbstractObject)source).classname, (uint)since_epoch, (uint)now, (int)offset ) ) );

        var tvdiff = Posix.timeval() { tv_sec = (time_t)offset };

        bool setHard = true;

        if ( try_adjtime ) // try adjtime to get a gradual shift
        {
            var res = Linux.adjtime( tvdiff );
            if ( res != 0 )
            {
                logger.warning( @"Can't adjtime(2): $(strerror(errno)); setting it hard" );
            }
            else
            {
                setHard = false;
            }
        }
        if ( setHard ) // set the time hard
        {
            var tvreal = Posix.timeval() { tv_sec = since_epoch };
            var res = tvreal.set_time_of_day();
            if ( res != 0 )
            {
                logger.warning( @"Can't settimeofday(2): $(strerror(errno))" );
            }
        }
    }

    public void onZoneReport( string zone, FsoTime.Source source )
    {
        assert( logger.debug( "%s reports time zone '%s'".printf( ((FsoFramework.AbstractObject)source).classname, zone ) ) );

        var newzone = GLib.Path.build_filename( zoneinfo_dir, zone );
        if ( !FsoFramework.FileHandling.isPresent( newzone ) )
        {
            logger.warning( @"Timezone file $newzone not present; ignoring zone report" );
            return;
        }
        else
        {
            try
            {
                GLib.FileUtils.set_contents( timezone_file, zone + "\n" );
            }
            catch ( GLib.FileError e )
            {
                logger.warning( @"Can't write to $timezone_file: $(e.message)" );
            }
        }

        assert( logger.debug( @"Removing $localtime_file and symlinking to $newzone" ) );

        var res = GLib.FileUtils.remove( localtime_file );
        if ( res != 0 )
        {
            logger.warning( @"Can't remove $(localtime_file): $(strerror(errno))" );
        }
        res = GLib.FileUtils.symlink( newzone, localtime_file );
        if ( res != 0 )
        {
            logger.warning( @"Can't symlink $localtime_file -> $newzone: $(strerror(errno))" );
        }
        else
        {
            /* found in mktime.c:
             * "POSIX.1 8.1.1 requires that whenever mktime() is called, the
             * time zone names contained in the external variable `tzname' shall
             * be set as if the tzset() function had been called."
             *
             * Hence, timezones will be reread, this we should be ok. */
            var t = GLib.Time();
            t.mktime();
        }
    }

    public void onLocationReport( double lat, double lon, int height, FsoTime.Source source )
    {
        assert( logger.debug( "%s reports position %.2f %.2f - %d".printf( ((FsoFramework.AbstractObject)source).classname, lat, lon, height ) ) );
    }
}

SyncTime.Service service;

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    service = new SyncTime.Service( subsystem );
    return SyncTime.MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsotdl.sync_time fso_register_function" );
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
