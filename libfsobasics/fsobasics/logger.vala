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

/**
 * Internal constants
 */
internal const string DEFAULT_LOG_TYPE = "none";
internal const string DEFAULT_LOG_LEVEL = "INFO";
internal const string DEFAULT_LOG_DESTINATION = "/tmp/frameworkd.log";

internal const string ENV_OVERRIDE_LOG_TO = "FSO_LOG_TO";
internal const string ENV_OVERRIDE_LOG_DESTINATION = "FSO_LOG_DESTINATION";
internal const string ENV_OVERRIDE_LOG_LEVEL = "FSO_LOG_LEVEL";

/**
 * First created logger will become default logger (one per process)
 **/
internal FsoFramework.Logger theDefaultLogger = null;

/**
 * Delegates
 */
public delegate string ReprDelegate();

/**
 * @interface Logger
 */
public interface FsoFramework.Logger : Object
{
    public abstract void setLevel( LogLevelFlags level );
    public abstract void setDestination( string destination );
    public abstract void setReprDelegate( ReprDelegate repr );

    public abstract LogLevelFlags getLevel();
    public abstract string getDestination();

    public abstract bool debug( string message );
    public abstract bool info( string message );
    public abstract bool warning( string message );
    public abstract bool error( string message );
    public abstract bool critical( string message );

    public static Logger defaultLogger()
    {
        return ( theDefaultLogger == null ? new NullLogger( "null" ) : theDefaultLogger );
    }

    /**
     * @returns @a Logger configured as requested in a certain conf file
     **/
    public static Logger createFromKeyFileName( string filename, string group, string domain )
    {
        var smk = new SmartKeyFile();
        string[] locations = { "./.%s".printf( filename ),
                               "%s/.%s".printf( Environment.get_home_dir(), filename ),
                               "/etc/%s".printf( filename ) };

        foreach ( var location in locations )
        {
            if ( smk.loadFromFile( location ) )
            {
                return Logger.createFromKeyFile( smk, group, domain );
            }
        }
        GLib.warning( @"Could not find $filename anywhere, returning StdErrLogger" );
        return new StdErrLogger( domain );
    }

    /**
     * @returns a logger with data from @a FsoFramework.SmartKeyFile
     **/
    public static Logger createFromKeyFile( FsoFramework.SmartKeyFile smk, string group, string domain )
    {
#if DEBUG
        GLib.debug( @"creating for domain $domain from group '$group", domain, group );
#endif
        string log_level = Environment.get_variable( ENV_OVERRIDE_LOG_LEVEL );
        if ( log_level == null )
        {
            log_level = smk.stringValue( group, "log_level", DEFAULT_LOG_LEVEL );
        }

        string log_to = Environment.get_variable( ENV_OVERRIDE_LOG_TO );
        if ( log_to == null )
            log_to = smk.stringValue( group, "log_to", DEFAULT_LOG_TYPE );

        string log_destination = Environment.get_variable( ENV_OVERRIDE_LOG_DESTINATION );
        if ( log_destination == null )
            log_destination = smk.stringValue( group, "log_destination", DEFAULT_LOG_DESTINATION );

        FsoFramework.Logger theLogger = null;
#if DEBUG
        GLib.debug( @"logging to $log_to" );
#endif
        switch ( log_to )
        {
            case "stderr":
                var logger = new FileLogger( domain );
                logger.setFile( log_to );
                theLogger = logger;
                break;
            case "stderr:colors":
                var logger = new FileLogger( domain );
                logger.setFile( "stderr" );
                logger.setColored( true );
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
                GLib.warning( @"Don't know how to instanciate logger type $log_to. Using StderrLogger." );
                var logger = new StdErrLogger( domain );
                theLogger = logger;
                break;
        }
        theLogger.setLevel( AbstractLogger.stringToLevel( log_level ) );
        return theLogger;
    }
}

/**
 * @class AbstractLogger
 */
public abstract class FsoFramework.AbstractLogger : FsoFramework.Logger, Object
{
    protected uint level = LogLevelFlags.LEVEL_INFO;
    protected string domain;
    protected string destination;
    protected bool colored;

    protected ReprDelegate reprdelegate;

    protected virtual void write( string message )
    {
    }

    protected string colorwrap( string message, string level )
    {
        var prefix = "";
        var postfix = "\033[m";

        switch ( level[0] )
        {
            case 'D':
                prefix = "\033[1;30m"; /* bold gray */
                break;
            case 'I':
                prefix = "\033[0;32m"; /* normal green */
                break;
            case 'W':
                prefix = "\033[0;33m"; /* normal yellow */
                break;
            case 'E':
                prefix = "\033[0;31m"; /* normal red */
                break;
            case 'C':
                prefix = "\033[1;31m"; /* bright red */
                break;
            default:
                prefix = "";
                postfix = "";
                break;
        }
        return "%s%s%s".printf( prefix, message, postfix );
    }

    protected virtual string format( string message, string level )
    {
        var t = TimeVal();
        var repr = ( reprdelegate != null ? reprdelegate() : "" );
        var str = "%s %s [%s] %s: %s\n".printf( t.to_iso8601(), domain, level, repr, message );
        return colored ? colorwrap( str, level ) : str;
    }

    public AbstractLogger( string domain )
    {
        this.domain = domain;
        if ( theDefaultLogger == null )
            theDefaultLogger = this;
    }

    public void setLevel( LogLevelFlags level )
    {
        this.level = (uint)level;
    }

    public LogLevelFlags getLevel()
    {
        return (LogLevelFlags) this.level;
    }

    public void setDestination( string destination )
    {
        this.destination = destination;
    }

    public string getDestination()
    {
        return this.destination;
    }

    public void setColored( bool on )
    {
        this.colored = on;
    }

    public bool getColored()
    {
        return this.colored;
    }

    public void setReprDelegate( ReprDelegate d )
    {
        this.reprdelegate = d;
    }

    public bool debug( string message )
    {
        if ( level >= (uint)LogLevelFlags.LEVEL_DEBUG )
            write( format( message, "DEBUG" ) );
        return true;
    }

    public bool info( string message )
    {
        if ( level >= (uint)LogLevelFlags.LEVEL_INFO )
            write( format( message, "INFO" ) );
        return true;
    }

    public bool warning( string message )
    {
        if ( level >= (uint)LogLevelFlags.LEVEL_WARNING )
            write( format( message, "WARNING" ) );
        return true;
    }

    public bool error( string message )
    {
        if ( level >= (uint)LogLevelFlags.LEVEL_ERROR )
            write( format( message, "ERROR" ) );
        return true;
    }

    public bool critical( string message )
    {
        write( format( message, "CRITICAL" ) );
        stderr.printf( "Aborting due to critical error:\n'%s'\n".printf( message ) );
        Posix.exit( Posix.EXIT_FAILURE );
        return true;
        //FIXME: Trigger dumping a backtrace, if possible
    }

    public static string levelToString( LogLevelFlags level )
    {
        switch ( level )
        {
            case LogLevelFlags.LEVEL_DEBUG:
                return "DEBUG";
            case LogLevelFlags.LEVEL_INFO:
                return "INFO";
            case LogLevelFlags.LEVEL_WARNING:
                return "WARNING";
            case LogLevelFlags.LEVEL_ERROR:
                return "ERROR";
            default:
                GLib.error( "logger: unknown log level value %d", level );
                return "UNKNOWN";
        }
    }

    public static LogLevelFlags stringToLevel( string level )
    {
        switch ( level )
        {
            case "debug":
            case "DEBUG":
                return LogLevelFlags.LEVEL_DEBUG;
            case "info":
            case "INFO":
                return LogLevelFlags.LEVEL_INFO;
            case "warning":
            case "WARNING":
                return LogLevelFlags.LEVEL_WARNING;
            case "error":
            case "ERROR":
                return LogLevelFlags.LEVEL_ERROR;
            default:
                message( "Loglevel not defined, reverting to INFO\n" );
                break;
        }
        return LogLevelFlags.LEVEL_INFO;
    }
}

/**
 * @class NullLogger
 */
public class FsoFramework.NullLogger : FsoFramework.AbstractLogger
{
    public NullLogger( string domain )
    {
        base( domain );
    }

    protected override void write( string message )
    {
    }
}

/**
 * @class FileLogger
 */
public class FsoFramework.FileLogger : FsoFramework.AbstractLogger
{
    int file = -1;

    protected override void write( string message )
    {
        assert( file != -1 );
        Posix.write( file, message, message.size() );
    }

    public FileLogger( string domain )
    {
        base( domain );
    }

    public void setFile( string filename, bool append = true )
    {
        if ( file != -1 )
        {
            this.destination = null;
            Posix.close( file );
        }
        if ( filename == "stderr" )
        {
            file = stderr.fileno();
        }
        else
        {
            int flags = Posix.O_WRONLY | ( append? Posix.O_APPEND : Posix.O_CREAT );
            file = Posix.open( filename, flags, Posix.S_IRUSR | Posix.S_IWUSR | Posix.S_IRGRP | Posix.S_IROTH);
        }
        if ( file == -1 )
        {
            GLib.error( "%s: %s", filename, Posix.strerror( Posix.errno ) );
        }
        this.destination  = filename;
    }

}

/**
 * @class StdErrLogger
 */
public class FsoFramework.StdErrLogger : FsoFramework.FileLogger
{
    public class StdErrLogger( string domain )
    {
        base( domain );
        setFile( "stderr" );
    }
}

/**
 * @class SyslogLogger
 */
public class FsoFramework.SyslogLogger : FsoFramework.AbstractLogger
{
    static string basename; // needs to be static, since openlog does not copy

    protected override void write( string message )
    {
        Posix.syslog( Posix.LOG_DEBUG, "%s", message );
    }

    /**
     * Overridden, since syslog already includes a timestamp
     **/
    protected override string format( string message, string level )
    {
        var repr = ( reprdelegate != null ? reprdelegate() : "" );
        var str = "%s [%s] %s: %s\n".printf( domain, level, repr, message );
        return str;
    }

    public SyslogLogger( string domain )
    {
        base( domain );
        if ( basename == null )
        {
            basename = "%s".printf( FsoFramework.Utility.programName() );
        }
        Posix.openlog( basename, Posix.LOG_PID | Posix.LOG_CONS, Posix.LOG_DAEMON );
    }
}
