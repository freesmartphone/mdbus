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
 **/

using GLib;

/**
 * SmartKeyFile
 */
public class FsoFramework.SmartKeyFile : Object
{
    private KeyFile kf = null;
    private bool loaded = false;
    private string filename;

    /**
     * Load keyfile into memory, searching in several well-known locations.
     *
     * @returns key file, if found. null, otherwise.
     **/
    public static SmartKeyFile createFromConfig( string filename )
    {
        var smk = new SmartKeyFile();
        string[] locations = { @"./$filename.conf",
                               @"$(Environment.get_home_dir())/.$filename.conf",
                               @"/etc/freesmartphone/$filename.conf",
                               @"/etc/$filename.conf" };

        foreach ( var location in locations )
        {
            if ( smk.loadFromFile( location ) )
            {
                return smk;
            }
        }
#if DEBUG
        GLib.debug( @"Could not find configuration file for $filename anywhere, returning empty keyfile" );
#endif
        return smk;
    }

    /**
     * Load keyfile into memory.
     *
     * @returns true, if successful. false, otherwise.
     */
    public bool loadFromFile( string filename )
    {
        assert( !loaded );
        this.filename = filename;
        kf = new KeyFile();

        try
        {
            kf.load_from_file( filename, KeyFileFlags.NONE );
        }
        catch ( Error e )
        {
#if DEBUG
            GLib.debug( @"Can't load keyfile from $filename: $(e.message)" );
#endif
            return false;
        }
        loaded = true;
        return true;
    }

    /*
     * generics do not work properly yet
     *
    public T getValue<T>( string section, string key, T defaultvalue )
    {
        message( "inttype=%d", typeof(int));
        message( "typecode=%d", typeof(T));
        if ( typeof( T ) == typeof( int ) )
        {
            try
            {
                return kf.get_integer( section, key );
            }
            catch ( KeyFileError e )
            {
                return defaultvalue;
            }
        }
        else if ( typeof( T ) == typeof( string ) )
        {
            try
            {
                return kf.get_string( section, key );
            }
            catch ( KeyFileError e )
            {
                return ((string)defaultvalue).strip();
            }
        }
        else if ( typeof( T ) == typeof( bool ) )
        {
            try
            {
                return kf.get_boolean( section, key );
            }
            catch ( KeyFileError e )
            {
                return defaultvalue;
            }
        }
        else
        {
#if DEBUG
            warning( "SmartKeyFile::getValue: unknown type code '%d'. Returning default value", typeof(T) );
#endif
            return defaultvalue;
        }
    }
    */

    //TODO: Consider rewriting this once Vala has generics
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
        return value.strip();
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

    public string[]? stringListValue( string section, string key, string[]? defaultvalue = null )
    {
        string[] value;

        try
        {
            value = kf.get_string_list( section, key );
        }
        catch ( KeyFileError e )
        {
            value = defaultvalue;
        }
        return value;
    }

    public bool hasSection( string section )
    {
        return kf.has_group( section );
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

    public bool hasKey( string section, string key )
    {
        try
        {
            return kf.has_key( section, key );
        }
        catch ( KeyFileError e )
        {
            return false;
        }
    }

    public List<string> keysWithPrefix( string section, string? prefix = null )
    {
        var list = new List<string>();
        string[] keys;

        try
        {
            keys = kf.get_keys( section );
        }
        catch ( KeyFileError e )
        {
            return list;
        }

        foreach ( var key in keys )
        {
            if ( prefix == null )
                list.append( key );
            else
                if ( key.has_prefix( prefix ) )
                    list.append( key );
        }
        return list;
    }

    public void write<T>( string section, string key, T value )
    {
        if ( typeof(T) == typeof(int) )
        {
            kf.set_integer( section, key, (int)value );
            markDirty();
        }
        else if ( typeof(T) == typeof(string) )
        {
            kf.set_string( section, key, (string)value );
            markDirty();
        }
        else
        {
            assert_not_reached();
        }
    }

    private void markDirty()
    {
        //FIXME: trigger delayed updates
        FileHandling.write( kf.to_data(), filename, true );
    }
}

/**
 * SmartKeyFileSection
 */
public class FsoFramework.SmartKeyFileSection : Object
{
    private FsoFramework.SmartKeyFile kf;
    private string section;

    private SmartKeyFileSection( FsoFramework.SmartKeyFile kf, string section )
    {
        this.kf = kf;
        this.section = section;
    }

    public static SmartKeyFileSection? openSection( FsoFramework.SmartKeyFile kf, string section )
    {
        if ( kf.hasSection( section ) )
            return new SmartKeyFileSection( kf, section );
        else
            return null;
    }
}
