/*
 * -- Mickey's DBus Utility V2 --
 *
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *                         Frederik 'playya' Sdun <frederik.sdun@googlemail.com>
 *                         Simon Busch <morphis@gravedo.de>
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
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

using GLib;

public class Argument : Object
{
    private const char[] start_chars = {'{', '[', '('};
    private const char[] end_chars = {'}', ']', ')'};
    private const char arg_separator = ',';

    private VariantBuilder vbuilder;

    public string name;
    public string type;

    public Argument( string name, string type, VariantBuilder vbuilder )
    {
        this.name = name;
        this.type = type;
        this.vbuilder = vbuilder;
    }

    public bool append( string arg )
    {
        return append_type( arg, type );
    }

    private bool append_type( string arg, string type )
    {
#if DEBUG
        debug( @"trying to parse argument $name of type $type delivered as $arg" );
#endif
        switch ( type.substring(0,1) )
        {
            case "y":
                uint8 value = (uint8) arg.to_int();
                vbuilder.add_value( new Variant.byte( value ) );
                break;
            case "b":
                bool value = ( arg == "true" || arg == "True" || arg == "1" );
                vbuilder.add_value( new Variant.boolean( value ) );
                break;
            case "n":
                int16 value = (int16) arg.to_int();
                vbuilder.add_value( new Variant.int16( value ) );
                break;
            case "i":
                int32 value = (int32) arg.to_int();
                vbuilder.add_value( new Variant.int32( value ) );
                break;
            case "q":
                uint16 value = (uint16) arg.to_int();
                vbuilder.add_value( new Variant.uint16( value ) );
                break;
            case "u":
                uint32 value = (uint32) arg.to_long();
                vbuilder.add_value( new Variant.uint32( value ) );
                break;
            case "t":
            case "x":
                uint64 value = (uint64) arg.to_long();
                vbuilder.add_value( new Variant.uint64( value ) );
                break;
            case "d":
                double value = arg.to_double();
                vbuilder.add_value( new Variant.double( value ) );
                break;
            case "s":
                vbuilder.add_value( new Variant.string( arg ) );
                break;
            case "o":
                vbuilder.add_value( new Variant.object_path( arg ) );
                break;
            /*
            case "a":
                var subsig = get_sub_signature( type.substring( 1, type.length - 1 ) );
                return append_array_type(arg, subsig);
            case "(":
                return append_struct_type(arg, type);
            case "{":
                return append_dict_entry_type(arg, iter, type);
            */
            default:
                stderr.printf( @"Unsupported type $type\n" );
                return false;
        }
        return true;
    }

    /*
    private bool append_array_type(string arg, DBus.RawMessageIter iter, string type)
    {
        //remove []
        var subiter = DBus.RawMessageIter();
#if DEBUG
        debug( @"parsing array '$arg' with subsignature '$type'" );
#endif
        assert( iter.open_container( DBus.RawType.ARRAY, type, subiter ) );
        foreach( var sub_arg in get_sub_args( arg.substring( 1, arg.length - 2 ) ) )
        {
            if(append_type( sub_arg, subiter, type ) == false)
                 return false;
        }
        assert( iter.close_container ( subiter ) );
        return true;

    }

    private bool append_struct_type(string arg, DBus.RawMessageIter iter, string type)
    {
#if DEBUG
        debug(@"Sending Struct with signature '$type' with arg: '$arg'" );
#endif
        int sigpos = 0;
        var subtype = type.substring(1, type.length - 2);
        var subiter = DBus.RawMessageIter();
        assert( iter.open_container( DBus.RawType.STRUCT, null, subiter ) );
        foreach(var s in get_sub_args( arg.substring( 1, arg.length - 2 )  ) )
        {
            var sig = get_sub_signature( subtype.offset( sigpos ) );
            sigpos += (int)sig.length;
            if( append_type(s, subiter, sig) == false)
                 return false;
        }
        assert( iter.close_container( subiter ) );
        return true;
    }

    public bool append_dict_entry_type( string arg, DBus.RawMessageIter iter, string type )
    {
#if DEBUG
        debug(@"Sending DictEntry with signature '$type' and arg '$arg'");
#endif
        var subtype = type.substring(1, type.length - 2 );
        var keytype = get_sub_signature(subtype);
        var valuetype = subtype.offset( keytype.length );

        var values = get_sub_args( arg, ':' );
        var key = values[0];
        var value = values[1];

        var subiter = DBus.RawMessageIter();
        assert( iter.open_container( DBus.RawType.DICT_ENTRY, null, subiter ) );

        if( append_type( key, subiter, keytype ) == false)
             return false;
        if( append_type( value, subiter, valuetype ) == false)
             return false;

        assert( iter.close_container( subiter ) );
        return true;
    }
    */

    private string get_sub_signature( string signature )
    {
        var result = "";
        int depth = 0;
        for(int i = 0; i < signature.length; i++)
        {
            char c = (char)signature[i];
            if( c == 'a')
            {
                 result += c.to_string();
                 continue;
            }
            else if( c in start_chars )
                 depth ++;
            else if( c in end_chars )
                 depth --;
            result += c.to_string();
            if (depth == 0)
                 break;
        }
        assert( depth == 0 );
        return result;
    }

    string[] get_sub_args(string arg, char separator = arg_separator)
    {
        var result = new string[0];
        var part = "";
        int depth = 0;
        for( int i = 0; i < arg.length; i ++ )
        {
            char c = (char)arg[i];
            if( c in start_chars )
                 depth ++;
            else if( c in end_chars )
                 depth --;
            part += c.to_string();
            if (depth == 0 && c == separator)
            {
                result += part.substring(0, part.length - 1 );
                part = "";
            }
        }
        assert(depth == 0);
        if( part.length != 0)
            result += part;
        return result;
    }
}
// vim:ts=4:sw=4:expandtab
