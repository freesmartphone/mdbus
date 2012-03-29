/*
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
void test_process_launch()
//===========================================================================
{
    var guard = new GProcessGuard();
    var ok = guard.launch( { "/bin/sleep", "1" } );
    assert( ok );
    assert( guard.isRunning() );
    var timeout = WaitForPredicate.Wait( 3, () => { return true; } );
    assert( !guard.isRunning() );
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
void test_process_kill_explicit()
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
void test_process_kill_implicit()
//===========================================================================
{
    var guard = new GProcessGuard();
    var ok = guard.launch( { "/bin/sleep", "60" } );
    assert( ok );
    bool signalok = false;
    guard.stopped.connect( ( guard ) => { signalok = true; } );
    int pid = guard._pid();
    guard = null;
    var timeout = WaitForPredicate.Wait( 5, () => {
        var res = Posix.kill( (Posix.pid_t)pid, 0 );
        return ( res == 0 );
    } );
    assert( !timeout );
}

//===========================================================================
void test_process_attach()
//===========================================================================
{
    Posix.pid_t init_pid = FsoFramework.Process.findByName( "init" );
    assert( init_pid == 1 );
    var guard = new GProcessGuard();
    var cmdline = "/sbin/init";
    assert( guard.attach( init_pid, cmdline.split( " " ) ) );
}

//===========================================================================
void test_process_find_by_name()
//===========================================================================
{
    assert( FsoFramework.Process.findByName( "init" ) == 1 );
}

//===========================================================================
void main (string[] args)
//===========================================================================
{
    Test.init (ref args);

    Test.add_func( "/Process/launch", test_process_launch );
    Test.add_func( "/Process/signals", test_process_signals );
    Test.add_func( "/Process/kill/explicit", test_process_kill_explicit );
    // Test.add_func( "/Process/kill/implicit", test_process_kill_implicit );
    Test.add_func( "/Process/attach", test_process_attach );
    Test.add_func( "/Process/find_by_name", test_process_find_by_name );

    Test.run ();
}

// vim:ts=4:sw=4:expandtab
