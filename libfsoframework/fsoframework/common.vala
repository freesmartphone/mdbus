/**
 * Copyright (C) 2009 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

internal const string DBUS_BUS_NAME = "org.freedesktop.DBus";
internal const string DBUS_BUS_PATH = "/org/freedesktop/DBus";
internal const string DBUS_BUS_INTERFACE = "org.freedesktop.DBus";

internal const string ENV_OVERRIDE_LOG_TO = "FSO_LOG_TO";
internal const string ENV_OVERRIDE_LOG_DESTINATION = "FSO_LOG_DESTINATION";
internal const string ENV_OVERRIDE_LOG_LEVEL = "FSO_LOG_LEVEL";

namespace FsoFramework
{

public const string DEFAULT_LOG_TYPE = "none";
public const string DEFAULT_LOG_LEVEL = "INFO";
public const string DEFAULT_LOG_DESTINATION = "/tmp/frameworkd.log";

internal const string PROC_SELF_CMDLINE = "/proc/self/cmdline";

internal static SmartKeyFile _masterkeyfile = null;
internal static string _prefix = null;

/**
 * @returns @a SmartKeyFile for frameworkd.conf
 **/
public static SmartKeyFile theMasterKeyFile()
{
    if ( _masterkeyfile == null )
    {
        _masterkeyfile = new SmartKeyFile();

        string[] locations = { "./frameworkd.conf",
                               "%s/.frameworkd.conf".printf( Environment.get_home_dir() ),
                               "/etc/frameworkd.conf" };

        foreach ( var location in locations )
        {
            if ( _masterkeyfile.loadFromFile( location ) )
            {
                message( "Using framework configuration file at '%s'", location );
                return _masterkeyfile;
            }
        }
        warning( "could not find framework configuration file." );
        return _masterkeyfile;
    }
    return _masterkeyfile;
}

/**
 * @returns @a Logger configured as requested in frameworkd.conf
 **/
public static Logger createLogger( string domain )
{
    SmartKeyFile smk = theMasterKeyFile();

    string global_log_level = Environment.get_variable( ENV_OVERRIDE_LOG_LEVEL );
    if ( global_log_level == null )
        global_log_level = smk.stringValue( "frameworkd", "log_level", DEFAULT_LOG_LEVEL );
    var log_level = smk.stringValue( domain, "log_level", global_log_level );

    string log_to = Environment.get_variable( ENV_OVERRIDE_LOG_TO );
    if ( log_to == null )
        log_to = smk.stringValue( "frameworkd", "log_to", DEFAULT_LOG_TYPE );

    string log_destination = Environment.get_variable( ENV_OVERRIDE_LOG_DESTINATION );
    if ( log_destination == null )
        log_destination = smk.stringValue( "frameworkd", "log_destination", DEFAULT_LOG_DESTINATION );

    Logger theLogger = null;

    switch ( log_to )
    {
        case "stderr":
            var logger = new FileLogger( domain );
            logger.setFile( log_to );
            theLogger = logger;
            break;
        case "file":
            var logger = new FileLogger( domain );
            logger.setFile( log_destination );
            theLogger = logger;
            break;
        case "syslog":
            var logger = new SyslogLogger( domain );
            theLogger = logger;
            break;
        case "none":
            var logger = new NullLogger( domain );
            theLogger = logger;
            break;
        default:
            assert( false );
            break;
    }

    theLogger.setLevel( AbstractLogger.stringToLevel( log_level ) );
    return theLogger;
}

/**
 * Return the prefix for the running program.
 **/
public static string getPrefixForExecutable()
{
    if ( _prefix == null )
    {
        var cmd = FileHandling.read( PROC_SELF_CMDLINE );
        var pte = Environment.find_program_in_path( cmd );
        _prefix = "";

        foreach ( var component in pte.split( "/" ) )
        {
            //debug( "dealing with component '%s', prefix = '%s'", component, _prefix );
            if ( component == "bin" )
                break;
            _prefix += "%s%c".printf( component, Path.DIR_SEPARATOR );
        }
    }
    return _prefix;
}

} /* namespace */