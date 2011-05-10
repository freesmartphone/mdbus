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

}
