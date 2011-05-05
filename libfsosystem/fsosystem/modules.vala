/*
 * Copyright (C) 2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

public errordomain SystemError
{
    ERROR
}

/* libc */
extern long init_module( void* data, ulong length, string options );
extern long delete_module( string name, uint flags );

namespace FsoFramework { namespace Kernel {

/**
 * Insert a module into the running kernel
 **/
public void insertModule( string filename, string? options = null ) throws Error
{
    uint8[] contents;
    FileUtils.get_data( filename, out contents );

    var ok = init_module( contents, contents.length, options );
    if ( ok != 0 )
    {
        throw new SystemError.ERROR( @"Can't insert module: $(strerror(errno))" );
    }
}

/**
 * Remove a module out of the running kernel
 **/
public void removeModule( string filename, bool wait = false, bool force = false ) throws Error
{
    uint flags = Posix.O_EXCL | Posix.O_NONBLOCK;
    if ( wait )
    {
        flags &= ~Posix.O_NONBLOCK;
    }
    if ( force )
    {
        flags |= Posix.O_TRUNC;
    }

    var ok = delete_module( filename, flags );
    if ( ok != 0 )
    {
        throw new SystemError.ERROR( @"Can't insert module: $(strerror(errno))" );
    }
}

/**
 * Load a module and its dependencies into the running kernel
 **/
public void probeModule( string modulename, string? options = null )
{
    throw new SystemError.ERROR( @"Not yet implemented" );
}

} /* namespace Kernel */
} /* namespace FsoFramework */

// vim:ts=4:sw=4:expandtab
