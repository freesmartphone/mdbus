/*
 * Copyright (C) 2009-2012 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

internal const uint READ_BUF_SIZE = 1024 * 1024;

namespace FsoFramework.FileHandling
{
    public bool createDirectory( string filename, Posix.mode_t mode )
    {
        return ( Posix.mkdir( filename, mode ) != -1 );
    }

    public bool removeTree( string path )
    {
        assert( theLogger.debug( @"removeTree: $path" ) );

        var dir = Posix.opendir( path );
        if ( dir == null )
        {
            assert( theLogger.debug( @"can't open dir: $path" ) );
            return false;
        }

        for ( unowned Posix.DirEnt entry = Posix.readdir( dir ); entry != null; entry = Posix.readdir( dir ) )
        {
            var current_path = "%s/%s".printf( path, (string) entry.d_name );

            if ( ( "." == (string)entry.d_name ) || ( ".." == (string)entry.d_name ) )
            {
                theLogger.debug( @"skipping $current_path" );
                continue;
            }

            assert( theLogger.debug( @"processing $current_path" ) );

            if ( GLib.FileUtils.test( current_path, GLib.FileTest.IS_REGULAR | GLib.FileTest.IS_SYMLINK ) )
            {
                var result = GLib.FileUtils.remove( current_path );
                if ( result == 0 )
                {
                    assert( theLogger.debug( @"$current_path removed" ) );
                    continue;
                }
                else
                {
                    theLogger.error( @"Failed to remove $current_path" );
                    return false;
                }
            }
            else if ( GLib.FileUtils.test( current_path, GLib.FileTest.IS_DIR ) )
            {
                if ( !removeTree( current_path ) )
                    return false;

                continue;
            }

            return false;
        }

        return GLib.FileUtils.remove( path ) == 0;
    }

    public bool isPresent( string filename )
    {
        Posix.Stat structstat;
        return ( Posix.stat( filename, out structstat ) != -1 );
    }

    public string readIfPresent( string filename )
    {
        return isPresent( filename ) ? read( filename ) : "";
    }

    public string[] listDirectory( string dirname )
    {
        var result = new string[] {};
        var dir = Posix.opendir( dirname );
        if ( dir != null )
        {
            unowned Posix.DirEnt dirent = Posix.readdir( dir );
            while ( dirent != null )
            {
                result += (string)dirent.d_name;
                dirent = Posix.readdir( dir );
            }
        }
        return result;
    }

    public string read( string filename )
    {
        char[] buf = new char[READ_BUF_SIZE];

        var fd = Posix.open( filename, Posix.O_RDONLY );
        if ( fd == -1 )
        {
            FsoFramework.theLogger.warning( @"Can't read-open $filename: $(Posix.strerror(Posix.errno))" );
        }
        else
        {
            ssize_t count = Posix.read( fd, buf, READ_BUF_SIZE );
            if ( count < 1 )
            {
                FsoFramework.theLogger.warning( @"Couldn't read anything from $filename: $(Posix.strerror(Posix.errno))" );
                Posix.close( fd );
            }
            else
            {
                Posix.close( fd );
                return ( (string)buf ).strip();
            }
        }
        return "";
    }

    public void write( string contents, string filename, bool create = false )
    {
        Posix.mode_t mode = 0;
        int flags = Posix.O_WRONLY;
        if ( create )
        {
            mode = Posix.S_IRUSR | Posix.S_IWUSR | Posix.S_IRGRP | Posix.S_IROTH;
            flags |= Posix.O_CREAT /* | Posix.O_EXCL */ | Posix.O_TRUNC;
        }
        var fd = Posix.open( filename, flags, mode );
        if ( fd == -1 )
        {
            FsoFramework.theLogger.warning( @"Can't write-open $filename: $(Posix.strerror(Posix.errno))" );
        }
        else
        {
            var length = contents.length;
            ssize_t written = Posix.write( fd, contents, length );
            if ( written != length )
            {
                FsoFramework.theLogger.warning( @"Couldn't write all bytes to $filename ($written of $length)" );
            }
            Posix.close( fd );
        }
    }

    public uint8[] readContentsOfFile( string filename ) throws GLib.FileError
    {
        Posix.Stat structstat;
        var ok = Posix.stat( filename, out structstat );
        if ( ok == -1 )
        {
            throw new GLib.FileError.FAILED( Posix.strerror(Posix.errno) );
        }

        var fd = Posix.open( filename, Posix.O_RDONLY );
        if ( fd == -1 )
        {
            throw new GLib.FileError.FAILED( Posix.strerror(Posix.errno) );
        }

        var buf = new uint8[structstat.st_size];
        var bread = Posix.read( fd, buf, structstat.st_size );
        if ( bread != structstat.st_size )
        {
            Posix.close( fd );
            throw new GLib.FileError.FAILED( @"Short read; got only $bread of $(structstat.st_size)" );
        }

        Posix.close( fd );
        return buf;
    }

    /**
     * Write buffer to file, supports partial writes.
     **/
    public void writeContentsToFile( uint8[] buffer, string filename ) throws GLib.FileError
    {
        var fd = Posix.open( filename, Posix.O_WRONLY );
        if ( fd == -1 )
        {
            throw new GLib.FileError.FAILED( Posix.strerror(Posix.errno) );
        }

        var written = 0;
        uint8* pointer = buffer;

        while ( written < buffer.length )
        {
            var wrote = Posix.write( fd, pointer + written, buffer.length - written );
            if ( wrote <= 0 )
            {
                Posix.close( fd );
                throw new GLib.FileError.FAILED( @"Short write; aborting after writing $written of buffer.length" );
            }
            written += (int)wrote;
        }
        Posix.close( fd );
    }

    public void writeBuffer( void* buffer, ulong length, string filename, bool create = false )
    {
        Posix.mode_t mode = 0;
        int flags = Posix.O_WRONLY;
        if ( create )
        {
            mode = Posix.S_IRUSR | Posix.S_IWUSR | Posix.S_IRGRP | Posix.S_IROTH;
            flags |= Posix.O_CREAT | Posix.O_EXCL;
        }
        var fd = Posix.open( filename, flags, mode );
        if ( fd == -1 )
        {
            FsoFramework.theLogger.warning( @"Can't write-open $filename: $(Posix.strerror(Posix.errno))" );
        }
        else
        {
            ssize_t written = Posix.write( fd, buffer, length );
            if ( written != length )
            {
                FsoFramework.theLogger.warning( @"Couldn't write all bytes to $filename ($written of $length)" );
            }
            Posix.close( fd );
        }
    }
}

