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

using GLib;

//===========================================================================
void test_path_is_mount_point()
{
    var path = new FsoFramework.FileSystem.Path( "/sys" );
    assert( path.is_mount_point() == true );
}

//===========================================================================
void test_path_is_absolute()
{
    var path = new FsoFramework.FileSystem.Path( "/is/absolut/path" );
    assert( path.is_absolute() == true );

    path = new FsoFramework.FileSystem.Path( "is/relative/path" );
    assert( path.is_absolute() == false );
}

//===========================================================================
void main( string[] args )
//===========================================================================
{
    Test.init( ref args );

    Test.add_func( "/FileSystem/Path/IsMountpoint", test_path_is_mount_point );
    Test.add_func( "/FileSystem/Path/IsAbsolute", test_path_is_absolute );

    Test.run();
}
