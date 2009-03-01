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
            write( message );
    }

    public void info( string message )
    {
        if ( level >= (uint)LogLevelFlags.LEVEL_INFO )
            write( message );
    }

    public void warning( string message )
    {
        if ( level >= (uint)LogLevelFlags.LEVEL_WARNING )
            write( message );
    }

    public void error( string message )
    {
        if ( level >= (uint)LogLevelFlags.LEVEL_ERROR )
            write( message );
    }
}

/**
 * FileLogger
 */
public class FsoFramework.FileLogger : FsoFramework.AbstractLogger
{
    int file = -1;

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
