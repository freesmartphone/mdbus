/**
 * Copyright (C) 2012 Simon Busch <morphis@gravedo.de>
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
using FsoFramework.Test;

public class TestCase0 : FsoFramework.Test.TestCase
{
    public TestCase0()
    {
        base( "TestCase0" );

        add_async_test( "AsyncWithTimeout",
                        cb => test_async_with_timeout( cb ),
                        res => test_async_with_timeout.end( res ),
                        4000 );
    }

    public async void test_async_with_timeout() throws GLib.Error, AssertError
    {
        bool done = false;

        Timeout.add_seconds( 3, () => {
            done = true;
            test_async_with_timeout.callback();
            return false;
        } );
        yield;

        Assert.is_true( done );
    }
}

public static int main( string[] args )
{
    Test.init( ref args );

    TestSuite root = TestSuite.get_root();
    root.add_suite( new TestCase0().get_suite() );

    Test.run();

    return 0;
}

// vim:ts=4:sw=4:expandtab
