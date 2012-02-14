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

//===========================================================================
void test_kobjectnotifier_add_match()
//===========================================================================
{
    var loop = new MainLoop();
    var success = false;
    var count = 0;

    BaseKObjectNotifier.addMatch( "add", "net", ( properties ) => {
        success = true;
        loop.quit();
    } );

    Timeout.add_seconds( 1, () => {
        if ( count == 10 )
            loop.quit();
        FsoFramework.FileHandling.write( " ", "/sys/class/net/lo/uevent" );
        count++;
        return true;
    } );

    loop.run();

    assert( success == true );
}

//===========================================================================
void main( string[] args )
//===========================================================================
{
    Test.init( ref args );

    Test.add_func( "/KObjectNotifier/AddMatch", test_kobjectnotifier_add_match );

    Test.run();
}

// vim:ts=4:sw=4:expandtab
