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

    public void parse( string response ) throws AtCommandError
    {
        var match = re.match( response, 0, out mi );
        if ( !match || mi == null )
            throw new AtCommandError.UNABLE_TO_PARSE( "%s does not match against RE %s".printf( response, re.get_pattern() ) );
    }

    public string to_string( int pos = 1 )
    {
        var res = mi.fetch( pos );
        return res;
    }
}

public class PlusCPIN : AtCommand
{
    public PlusCPIN()
    {
        re = new Regex( """\+CPIN:\ "?(?P<string>[^"]*)"?""" );
    }
}


static GLib.HashTable<string, AtCommand> _commandTable;

public AtCommand commandFactory( string command )
{
    if ( _commandTable == null )
        initCommandFactory();
    var cmd = _commandTable.lookup( command );
    assert( cmd != null );
    return cmd;
}

public void initCommandFactory()
{
    assert( _commandTable == null );
    debug( "init command factory" );
    _commandTable = new GLib.HashTable<string, AtCommand>( GLib.str_hash, GLib.str_equal );

    _commandTable.insert( "PlusCPIN", new PlusCPIN() );
}

} /* namespace FsoGsm */
