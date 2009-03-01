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
 * Logger
 */
public interface FsoFramework.Logger : Object
{
    public abstract void setLevel( LogLevelFlags level );
    public abstract void setDestination( string destination );
    public abstract void debug( string message );
    public abstract void info( string message );
    public abstract void warning( string message );
    public abstract void error( string message );
}

/**
 * AbstractLogger
 */
public abstract class FsoFramework.AbstractLogger : FsoFramework.Logger, Object
{
    protected uint level = LogLevelFlags.LEVEL_INFO;
    protected string domain;
    protected string destination;

    protected virtual void write( string message )
    {
    }

    protected virtual string format( string message, string level )
    {
        var t = TimeVal();
        var str = "%s %s [%s] %s\n".printf( t.to_iso8601(), domain, level, message );
        return str;
    }

    public AbstractLogger( string domain )
    {
        this.domain = domain;
    }

    public void setLevel( LogLevelFlags level )
    {
        this.level = (uint)level;
    }

    public void setDestination( string destination )
    {
        this.destination = destination;
    }

    public void debug( string message )
    {
        if ( level >= (uint)LogLevelFlags.LEVEL_DEBUG )
            write( format( message, "DEBUG" ) );
    }

    public void info( string message )
    {
        if ( level >= (uint)LogLevelFlags.LEVEL_INFO )
            write( format( message, "INFO" ) );
    }

    public void warning( string message )
    {
        if ( level >= (uint)LogLevelFlags.LEVEL_WARNING )
            write( format( message, "WARNING" ) );
    }

    public void error( string message )
    {
        if ( level >= (uint)LogLevelFlags.LEVEL_ERROR )
            write( format( message, "ERROR" ) );
    }

    public static string levelToString( LogLevelFlags level )
    {
    // FIXME: might use a static HashTable here, might also be overkill for 4 values
        switch ( level )
        {
            case LogLevelFlags.LEVEL_DEBUG: return "DEBUG";
            case LogLevelFlags.LEVEL_INFO: return "INFO";
            case LogLevelFlags.LEVEL_WARNING: return "WARNING";
            case LogLevelFlags.LEVEL_ERROR: return "ERROR";
            default: assert( false ); break;
        }
        return "N/A";
    }

    public static LogLevelFlags stringToLevel( string level )
    {
        switch ( level )
        {
            case "debug":
                case "DEBUG": return LogLevelFlags.LEVEL_DEBUG;
            case "info":
                case "INFO": return LogLevelFlags.LEVEL_INFO;
            case "warning":
                case "WARNING": return LogLevelFlags.LEVEL_WARNING;
            case "error":
                case "ERROR": return LogLevelFlags.LEVEL_ERROR;
                default: assert( false ); break;
        }
        return LogLevelFlags.LEVEL_INFO;
    }
}

/**
 * FileLogger
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

    public void setFile( string filename, bool append = false )
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
            GLib.error( "%s", Posix.strerror( Posix.errno ) );

        this.destination  = filename;
    }

}
/**
 * SyslogLogger
 */
public class FsoFramework.SyslogLogger : FsoFramework.AbstractLogger
{
    protected override void write( string message )
    {
        PosixExtra.syslog( PosixExtra.LOG_DEBUG, "%s", message );
    }

    /**
     * Overridden, since syslog already includes a timestamp
     **/
    protected override string format( string message, string level )
    {
        var str = "%s [%s] %s\n".printf( domain, level, message );
        return str;
    }

    public SyslogLogger( string domain )
    {
        base( domain );
        string basename = Path.get_basename( Environment.get_prgname() );
        PosixExtra.openlog( basename, PosixExtra.LOG_PID | PosixExtra.LOG_CONS, PosixExtra.LOG_DAEMON );
    }
}

