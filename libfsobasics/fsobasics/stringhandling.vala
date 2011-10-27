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

internal static GLib.Regex _keyValueRe = null;

namespace FsoFramework.StringHandling
{
    //TODO: make this a generic, once Vala supports it
    public string stringListToString( string[] list )
    {
        if ( list.length == 0 )
            return "[]";

        var res = "[ ";

        for( int i = 0; i < list.length; ++i )
        {
            res += "\"%s\"".printf( list[i] );
            if ( i < list.length-1 )
                res += ", ";
            else
                res += " ]";
        }
        return res;
    }

    public T enumFromString<T>( string value, T default_value )
    {
        T result = enumFromName<T>( value );
        if ( ((int) result) == -1 )
        {
            result = enumFromNick<T>( value );
            if ( ((int) result) == -1 )
            {
                result = default_value;
            }
        }
        return result;
    }

    public string enumToString<T>( T value )
    {
        EnumClass ec = (EnumClass) typeof( T ).class_ref();
        unowned EnumValue? ev = ec.get_value( (int)value );
        return ev == null ? "Unknown Enum value for %s: %i".printf( typeof( T ).name(), (int)value ) : ev.value_name;
    }

    public string enumToNick<T>( T value )
    {
        var ec = (EnumClass) typeof(T).class_ref();
        var ev = ec.get_value( (int)value );
        return ev == null ? "Unknown Enum value for %s: %i".printf( typeof( T ).name(), (int)value ) : ev.value_nick;
    }

    public T enumFromName<T>( string name )
    {
        var ec = (EnumClass) typeof(T).class_ref();
        var ev = ec.get_value_by_name( name );
        return ev == null ? -1 : ev.value;
    }

    public T enumFromNick<T>( string nick )
    {
        var ec = (EnumClass) typeof(T).class_ref();
        var ev = ec.get_value_by_nick( nick );
        return ev == null ? -1 : ev.value;
    }

    public T convertEnum<F,T>( F from )
    {
        var s = FsoFramework.StringHandling.enumToNick<F>( from );
        return FsoFramework.StringHandling.enumFromNick<T>( s );
    }

    public GLib.HashTable<string,string> splitKeyValuePairs( string str )
    {
        var result = new GLib.HashTable<string,string>( GLib.str_hash, GLib.str_equal );
        if ( _keyValueRe == null )
        {
            try
            {
                _keyValueRe = new GLib.Regex( "(?P<key>[A-Za-z0-9]+)=(?P<value>[A-Za-z0-9.]+)" );
            }
            catch ( GLib.RegexError e )
            {
                assert_not_reached(); // regex invalid
            }
        }
        GLib.MatchInfo mi;
        var next = _keyValueRe.match( str, GLib.RegexMatchFlags.NEWLINE_CR, out mi );
        while ( next )
        {
    #if DEBUG
            debug( "got match '%s' = '%s'", mi.fetch_named( "key" ), mi.fetch_named( "value" ) );
    #endif
            result.insert( mi.fetch_named( "key" ), mi.fetch_named( "value" ) );
            try
            {
                next = mi.next();
            }
            catch ( GLib.RegexError e )
            {
    #if DEBUG
                debug( @"regex error: $(e.message)" );
    #endif
                next = false;
            }
        }
        return result;
    }

    public string hexdump( uint8[] array, int linelength = 16, string prefix = "", uchar unknownCharacter = '?' )
    {
        if ( array.length < 1 )
        {
            return "";
        }

        string result = "";

        int BYTES_PER_LINE = linelength;

        var hexline = new StringBuilder( prefix );
        var ascline = new StringBuilder();
        uchar b;
        int i;

        for ( i = 0; i < array.length; ++i )
        {
            b = array[i];
            hexline.append_printf( "%02X ", b );
            if ( 31 < b && b < 128 )
                ascline.append_printf( "%c", b );
            else
                ascline.append_printf( "." );

            if ( i % BYTES_PER_LINE+1 == BYTES_PER_LINE )
            {
                hexline.append( ascline.str );
                result += hexline.str;
                result += "\n";
                hexline = new StringBuilder( prefix );
                ascline = new StringBuilder();
            }
        }

        if ( i % BYTES_PER_LINE  != BYTES_PER_LINE )
        {
            while ( hexline.len < 3 * BYTES_PER_LINE )
            {
                hexline.append_c( ' ' );
            }

            hexline.append( ascline.str );
            result += hexline.str;
            result += "\n";
        }

        return result.strip();
    }

    public string filterByAllowedCharacters( string input, string allowed )
    {
        var output = "";

        for ( var i = 0; i < input.length; ++i )
        {
            var str = input[i].to_string();
            if ( str in allowed )
            {
                output += str;
            }
        }
        return output;
    }
}

