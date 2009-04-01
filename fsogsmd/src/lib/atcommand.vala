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

public errordomain AtCommandError
{
    UNABLE_TO_PARSE,
}

namespace FsoGsm
{

public abstract class AtCommand : GLib.Object
{
    protected Regex re;
    protected MatchInfo mi;

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
}

static GLib.HashTable<string, AtCommand> _commandTable;

public AtCommand atCommandFactory( string command )
{
    if ( _commandTable == null )
        registerAtCommands();
    assert( _commandTable != null );
    var cmd = _commandTable.lookup( command );
    assert( cmd != null );
    return cmd;
}

public void registerAtCommands()
{
    _commandTable = new GLib.HashTable<string, AtCommand>( GLib.str_hash, GLib.str_equal );
    registerGeneratedAtCommands( _commandTable );
}

} /* namespace FsoGsm */
