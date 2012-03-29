/**
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
using FsoFramework;

MainLoop loop;

public const string TEST_FILENAME = "./this-testfile-no-content";

public void myCallback( Linux.InotifyMaskFlags flags, uint32 cookie, string? name )
{
    debug( "got callback %d, %d, %s", (int)flags, (int)cookie, name );
    loop.quit();
}

//===========================================================================
void test_inotifier_add()
//===========================================================================
{
    FsoFramework.FileHandling.write( "Hello World", TEST_FILENAME, true );
    INotifier.add( TEST_FILENAME, Linux.InotifyMaskFlags.MODIFY, myCallback );
    Timeout.add_seconds( 1, () => {
        FsoFramework.FileHandling.write( "Dutty Content", TEST_FILENAME );
        return false;
    } );
    loop = new MainLoop();
    loop.run();
    FileUtils.unlink( TEST_FILENAME );
}

//===========================================================================
void test_inotifier_remove()
//===========================================================================
{
    FsoFramework.FileHandling.write( "Hello World", TEST_FILENAME, true );
    INotifier.remove( 123456 ); // not existing
    var handle = INotifier.add( TEST_FILENAME, Linux.InotifyMaskFlags.CREATE, myCallback );
    INotifier.remove( handle );
    FileUtils.unlink( TEST_FILENAME );
}

//===========================================================================
void main( string[] args )
//===========================================================================
{
    Test.init( ref args );

    Test.add_func( "/INotifier/Add", test_inotifier_add );
    Test.add_func( "/INotifier/Remove", test_inotifier_remove );

    Test.run();
}

// vim:ts=4:sw=4:expandtab
