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

public errordomain FsoGsm.AtCommandError
{
    UNABLE_TO_PARSE,
}

public abstract class FsoGsm.AtCommand : GLib.Object
{
    protected Regex re;
    protected MatchInfo mi;
    protected string[] prefix;

    public virtual void parse( string response ) throws AtCommandError
    {
        bool match;
        match = re.match( response, 0, out mi );

        if ( !match || mi == null )
            throw new AtCommandError.UNABLE_TO_PARSE( "%s does not match against RE %s".printf( response, re.get_pattern() ) );
    }

    public string to_string( string name )
    {
        var res = mi.fetch_named( name );
        return res;
    }

    public int to_int( string name )
    {
        var res = mi.fetch_named( name );
        if ( res == null )
            return -1; // indicates parameter not present
        return res.to_int();
    }

    public bool is_valid_prefix( string line )
    {
        if ( prefix == null ) // free format
            return true;
        for ( int i = 0; i < prefix.length; ++i )
        {
            if ( line.has_prefix( prefix[i] ) )
                return true;
        }
        return false;
    }
}
