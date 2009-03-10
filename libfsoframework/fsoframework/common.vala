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

namespace FsoFramework
{

public const string DEFAULT_LOG_TYPE = "syslog";
public const string DEFAULT_LOG_LEVEL = "INFO";
public const string DEFAULT_LOG_DESTINATION = "/tmp/frameworkd.log";

internal static SmartKeyFile _masterkeyfile = null;

public static SmartKeyFile theMasterKeyFile()
{
    if ( _masterkeyfile == null )
    {
        _masterkeyfile = new SmartKeyFile();
        var try0 = "./frameworkd.conf";
        var try1 = "%s/.frameworkd.conf".printf( Environment.get_home_dir() );
        var try2 = "/etc/frameworkd.conf";
        if ( !_masterkeyfile.loadFromFile( try0 ) && !_masterkeyfile.loadFromFile( try1 ) && !_masterkeyfile.loadFromFile( try2 ) )
        {
            warning( "could not load %s nor %s nor %s", try0, try1, try2 );
        }
    }
    return _masterkeyfile;
}

public static Logger createLogger( string domain )
{
    SmartKeyFile smk = theMasterKeyFile();
    var global_log_level = smk.stringValue( "frameworkd", "log_level", DEFAULT_LOG_LEVEL );
    var log_level = smk.stringValue( domain, "log_level", global_log_level );
    var log_to = smk.stringValue( "frameworkd", "log_to", DEFAULT_LOG_TYPE );

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
            var log_destination = smk.stringValue( "frameworkd", "log_destination", DEFAULT_LOG_DESTINATION );
            logger.setFile( log_destination );
            theLogger = logger;
            break;
        case "syslog":
            var logger = new SyslogLogger( domain );
            theLogger = logger;
            break;
        default:
            assert( false );
            break;
    }

    theLogger.setLevel( AbstractLogger.stringToLevel( log_level ) );
    return theLogger;

}

} /* namespace */