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
using FsoFramework;

//===========================================================================
void test_process_launch()
//===========================================================================
{
    var guard = new GProcessGuard();
    var ok = guard.launch( { "/bin/sleep", "5" } );
    assert( ok );
}

//===========================================================================
void test_process_signals()
//===========================================================================
{
    var guard = new GProcessGuard();
    var ok = guard.launch( { "/bin/sleep", "1" } );
    assert( ok );
    bool signalok = false;
    guard.stopped.connect( ( guard ) => { signalok = true; } );

    var timeout = WaitForPredicate.Wait( 5, () => { return !signalok; } );
    assert( !timeout );
}

//===========================================================================
void test_process_kill()
//===========================================================================
{
    var guard = new GProcessGuard();
    var ok = guard.launch( { "/bin/sleep", "60" } );
    assert( ok );
    bool signalok = false;
    guard.stopped.connect( ( guard ) => { signalok = true; } );
    var timeout = WaitForPredicate.Wait( 5, () => {
        guard.stop();
        return !signalok;
    } );
    assert( !timeout );
}

//===========================================================================
void main (string[] args)
//===========================================================================
{
    Test.init (ref args);

    Test.add_func( "/Process/launch", test_process_launch );
    Test.add_func( "/Process/signals", test_process_signals );
    Test.add_func( "/Process/kill", test_process_kill );

    Test.run ();
}
