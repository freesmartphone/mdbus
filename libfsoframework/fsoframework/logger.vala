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
 * AbstractLogger
 */
public abstract class FsoFramework.AbstractLogger : Object
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

        int flags = Posix.O_EXCL | Posix.O_CREAT | Posix.O_WRONLY;
        if ( append )
            flags |= Posix.O_APPEND;
        file = Posix.open( filename, flags, Posix.S_IRWXU );

        this.destination  = filename;
    }

}
