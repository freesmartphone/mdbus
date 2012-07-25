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

public abstract class FsoTest.GsmBaseTest : FsoFramework.Test.TestCase
{
    private IProcessGuard fsogsmd_process;
    private IProcessGuard phonesim_process;

    protected IRemotePhoneControl remote_control { get; private set; }

    //
    // private
    //

    private bool start_daemon()
    {
        // FIXME check wether one of both processes is already running

        fsogsmd_process = new GProcessGuard();
        phonesim_process = new GProcessGuard();

        // FIXME prefix with directory where the phonesim configuration is stored
        if ( !phonesim_process.launch( new string[] { "phonesim", "-p", "3001", "-gui", "phonesim-default.xml" } ) )
            return false;

        Posix.sleep( 3 );

        if ( !fsogsmd_process.launch( new string[] { "fsogsmd", "--test" } ) )
            return false;

        Posix.sleep( 3 );

        return true;
    }

    private void stop_daemon()
    {
        GLib.Log.set_always_fatal( GLib.LogLevelFlags.LEVEL_CRITICAL );
        fsogsmd_process.stop();
        phonesim_process.stop();
    }


    //
    // protected
    //

    protected GsmBaseTest( string name )
    {
        base( name );
        remote_control = new PhonesimRemotePhoneControl();
        start_daemon();
    }

    //
    // public
    //

    public void shutdown()
    {
        stop_daemon();
    }
}

// vim:ts=4:sw=4:expandtab
