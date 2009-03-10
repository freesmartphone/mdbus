/**
 * Copyright (C) 2009 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

/**
 * SmartKeyFile
 */
public class FsoFramework.SmartKeyFile : Object
{
    private KeyFile kf = null;
    private bool loaded = false;

    /**
     * Load keyfile into memory
     * @return true, if successful. false, otherwise.
     */
    public bool loadFromFile( string filename )
    {
        assert( !loaded );
        kf = new KeyFile();

        try
        {
            kf.load_from_file( filename, KeyFileFlags.NONE );
        }
        catch ( Error e )
        {
            return false;
        }
        loaded = true;
        return true;
    }

    public string stringValue( string section, string key, string defaultvalue = "" )
    {
        string value;

        try
        {
            value = kf.get_string( section, key );
        }
        catch ( KeyFileError e )
        {
            value = defaultvalue;
        }
        return value;
    }

    public int intValue( string section, string key, int defaultvalue = 0 )
    {
        int value;

        try
        {
            value = kf.get_integer( section, key );
        }
        catch ( KeyFileError e )
        {
            value = defaultvalue;
        }
        return value;
    }

    public bool boolValue( string section, string key, bool defaultvalue = false )
    {
        bool value;

        try
        {
            value = kf.get_boolean( section, key );
        }
        catch ( KeyFileError e )
        {
            value = defaultvalue;
        }
        return value;
    }

    public List<string> sectionsWithPrefix( string? prefix = null )
    {
        var list = new List<string>();
        var groups = kf.get_groups();

        foreach ( var group in groups )
        {
            if ( prefix == null )
                list.append( group );
            else
                if ( group.has_prefix( prefix ) )
                    list.append( group );
        }
        return list;
    }

}
