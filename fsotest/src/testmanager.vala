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

namespace FsoTest
{
    public delegate void TestMethod() throws GLib.Error;
}

public class FsoTest.TestManager : GLib.Object
{
    private List<Fixture> fixtures = new List<Fixture>();

    public void add_fixture( Fixture fixture )
    {
        fixtures.append( fixture );
    }

    public bool run_test_method( string test_name, TestMethod test_method )
    {
        try
        {
            test_method();
            FsoFramework.theLogger.info( @"$test_name :: OK" );
        }
        catch ( GLib.Error err )
        {
            FsoFramework.theLogger.error( @"$test_name :: FAILED: $(err.message)" );
            return false;
        }

        return true;
    }

    public void run_all()
    {
        foreach ( var fixture in fixtures )
        {
            FsoFramework.theLogger.info( @"================================================" );
            FsoFramework.theLogger.info( @" Fixture $(fixture.name)" );
            FsoFramework.theLogger.info( @"================================================" );

            fixture.setup();

            if ( fixture.run( this ) )
            {
                FsoFramework.theLogger.info( @"==> SUCCESSFULL" );
            }
            else
            {
                FsoFramework.theLogger.error( @"==> FAILED" );
            }

            fixture.teardown();
        }
    }
}

// vim:ts=4:sw=4:expandtab
