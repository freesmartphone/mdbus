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

void test_are_equal()
{
    try
    {
        FsoFramework.Test.Assert.are_equal<string>( "Test1", "Test2", "Should not be equal" );
        assert( false ); // Should only reached when test failed
    }
    catch ( FsoFramework.Test.AssertError err ) { }

    try
    {
        FsoFramework.Test.Assert.are_equal<int>( 101, 102, "Should not be equal" );
        assert( false ); // Should only reached when test failed
    }
    catch ( FsoFramework.Test.AssertError err ) { }

    try
    {
        FsoFramework.Test.Assert.are_equal<string>( "Test1", "Test1", "Should be equal" );
        FsoFramework.Test.Assert.are_equal<int>( 101, 101, "Should be equal" );
    }
    catch ( GLib.Error err )
    {
        assert( false );
    }
}

void test_are_not_equal()
{
    try
    {
        FsoFramework.Test.Assert.are_not_equal<string>( "Test1", "Test1", "Should not be equal" );
        assert( false ); // Should only reached when test failed
    }
    catch ( FsoFramework.Test.AssertError err ) { }

    try
    {
        FsoFramework.Test.Assert.are_not_equal<int>( 101, 101, "Should not be equal" );
        assert( false ); // Should only reached when test failed
    }
    catch ( FsoFramework.Test.AssertError err ) { }


    try
    {
        FsoFramework.Test.Assert.are_not_equal<string>( "Test1", "Test2", "Should be not equal" );
        FsoFramework.Test.Assert.are_not_equal<int>( 101, 102, "Should be not equal" );
    }
    catch ( GLib.Error err )
    {
        assert( false );
    }
}

void test_is_true()
{
    try
    {
        FsoFramework.Test.Assert.is_true( false );
        assert( false ); // Should only reached when test failed
    }
    catch ( FsoFramework.Test.AssertError err ) { }

    try
    {
        FsoFramework.Test.Assert.is_true( true );
    }
    catch ( GLib.Error err )
    {
        assert( false );
    }
}

void test_is_false()
{
    try
    {
        FsoFramework.Test.Assert.is_false( true );
        assert( false ); // Should only reached when test failed
    }
    catch ( FsoFramework.Test.AssertError err ) { }

    try
    {
        FsoFramework.Test.Assert.is_false( false );
    }
    catch ( GLib.Error err )
    {
        assert( false );
    }
}

void test_fail()
{
    try
    {
        FsoFramework.Test.Assert.fail( "fail" );
        assert( false );
    }
    catch ( FsoFramework.Test.AssertError err )
    {
    }
}

void main( string[] args )
{
    Test.init( ref args );

    Test.add_func( "/FsoFramework/Test/Assert/AreEqual", test_are_equal );
    Test.add_func( "/FsoFramework/Test/Assert/AreNotEqual", test_are_not_equal );
    Test.add_func( "/FsoFramework/Test/Assert/IsTrue", test_is_true );
    Test.add_func( "/FsoFramework/Test/Assert/IsFalse", test_is_false );
    Test.add_func( "/FsoFramework/Test/Assert/Fail", test_fail );

    Test.run();
}

// vim:ts=4:sw=4:expandtab
