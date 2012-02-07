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

public errordomain FsoTest.AssertError
{
    UNEXPECTED_VALUE,
    UNEXPECTED_STATE,
}

public class FsoTest.Assert : GLib.Object
{

    private static void throw_unexpected_value( string info, string message ) throws GLib.Error
    {
        throw new AssertError.UNEXPECTED_VALUE( info +  ( message.length > 0 ? @" : $(message)" : "" ) );
    }

    public static void are_equal<T>( T expected, T actual, string message = "" ) throws GLib.Error
    {
        if ( expected != actual )
            throw_unexpected_value( "Actual value is not the same as the expected one", message );
    }

    public static void are_not_equal<T>( T not_expected, T actual, string message = "" ) throws GLib.Error
    {
        if ( not_expected == actual )
            throw_unexpected_value( "Actual value is the same as the not expected one", message );
    }

    public static void is_true( bool actual, string message = "" ) throws GLib.Error
    {
        if ( !actual )
            throw_unexpected_value( "Supplied value is not true", message );
    }

    public static void is_false( bool actual, string message = "" ) throws GLib.Error
    {
        if ( actual )
            throw_unexpected_value( "Supplied value is not false", message );
    }

    public static void fail( string message ) throws GLib.Error
    {
        throw new AssertError.UNEXPECTED_STATE( message );
    }

    public static void should_throw_async( AsyncBegin fbegin, AsyncFinish ffinish, string domain, string message = "" ) throws GLib.Error
    {
        try
        {
            if ( !wait_for_async( 200, fbegin, ffinish ) )
                throw_unexpected_value( "Execution of async method didn't returns the expected value", message );
        }
        catch ( GLib.Error err )
        {
            if ( err.domain.to_string() != domain )
                throw_unexpected_value( @"Didn't receive the expected exception of type $domain", message );
            return;
        }

        throw new AssertError.UNEXPECTED_STATE( @"Function didn't throw expected exception" );
    }
}

// vim:ts=4:sw=4:expandtab
