/*
 * (C) 2011 Simon Busch <morphis@gravedo.de>
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

public static int main( string[] args )
{
    var tm = new FsoTest.TestManager();

    Test.log_set_fatal_handler( ( domain, log_levels, message ) => {
        FsoFramework.theLogger.error( @"Fatal: $domain -> $message" );
        return false;
    } );

    tm.add_fixture( new FsoTest.TestUsage() );
    tm.add_fixture( new FsoTest.TestGSM() );
    tm.run_all();

    return 0;
}

// vim:ts=4:sw=4:expandtab
