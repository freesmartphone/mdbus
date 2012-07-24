/*
 * (C) 2011-2012 Simon Busch <morphis@gravedo.de>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 */

using GLib;
using FsoFramework;
using FsoFramework.Test;

FsoTest.GsmCallTest gsm_call_suite = null;

public static void sighandler( int signum )
{
    Posix.signal( signum, null ); // restore original sighandler
    gsm_call_suite.shutdown();
    FsoFramework.theLogger.info( "received signal -%d, exiting.".printf( signum ) );
}

public static int main( string[] args )
{
    GLib.Test.init( ref args );

    Posix.signal( Posix.SIGINT, sighandler );
    Posix.signal( Posix.SIGTERM, sighandler );
    Posix.signal( Posix.SIGBUS, sighandler );
    Posix.signal( Posix.SIGSEGV, sighandler );
    Posix.signal( Posix.SIGABRT, sighandler );
    Posix.signal( Posix.SIGTRAP, sighandler );

    TestSuite root = TestSuite.get_root();
    gsm_call_suite = new FsoTest.GsmCallTest();
    root.add_suite( gsm_call_suite.get_suite() );

    GLib.Test.run();

    gsm_call_suite.shutdown();

    return 0;
}

// vim:ts=4:sw=4:expandtab
