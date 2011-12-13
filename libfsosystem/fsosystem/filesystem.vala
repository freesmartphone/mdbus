/*
 * Copyright (C) 2011 Simon Busch <morphis@gravedo.de>
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

namespace FsoFramework.FileSystem
{
    public bool isPresent( string filename )
    {
        Posix.Stat structstat;
        return ( Posix.stat( filename, out structstat ) != -1 );
    }

    public bool createDirectory( string filename, Posix.mode_t mode )
    {
        return ( Posix.mkdir( filename, mode ) != -1 );
    }

    public bool mountFilesystem( string source, string target, string type, Linux.MountFlags flags )
    {
        return ( Linux.mount( source, target, type, flags ) != -1 );
    }

    public bool mountFilesystemAt( Posix.mode_t mode, string source, string target, string type, Linux.MountFlags flags )
    {
        if ( !isPresent( target ) )
        {
            debug( @"$target is not present, trying to create..." );
            if ( !createDirectory( target, mode ) )
            {
                warning( @"Can't create $target: $(strerror(errno))" );
                return false;
            }
        }
        return mountFilesystem( source, target, type, flags );
    }

    /**
     * FIXME: This method is currently available in both libfsobasics and libfsosystem;
     * We need to fix this as fast as possible!
     */
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
            warning( @"Can't write-open $filename: $(Posix.strerror(Posix.errno))" );
        }
        else
        {
            var length = contents.length;
            ssize_t written = Posix.write( fd, contents, length );
            if ( written != length )
            {
                warning( @"Couldn't write all bytes to $filename ($written of $length)" );
            }
            Posix.close( fd );
        }
    }
}

// vim:ts=4:sw=4:expandtab
