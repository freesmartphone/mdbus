#!/usr/bin/env python
"""
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
"""

import sys, types

#========================================================================#
prefixmap = { \
    "+": "plus",
    "-": "minus",
    "$": "dollar",
    "@": "at",
    "_": "underscore",
    "&": "ampersand",
    "%": "percent",
    }
def nameToClassName( name ):
    return prefixmap[name[0]].capitalize() + name[1:]

#========================================================================#
commands = { \
     "+CFUN": [ "+CFUN: ", "<int:fun>" ],
     "+CPIN": [ "+CPIN: ", "<string:pin>" ],
     }


#========================================================================#
class CommandTranslator( object ):
#========================================================================#

    template = """
public class %s : AtCommand
{
    // declare instance vars
%s

    // construction
    public %s()
    {
        re = new Regex( \"\"\"%s\"\"\" );
    }

    // parse
    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        // populate instance vars
%s
    }
}
"""

    def __init__( self, command, format ):
        self.command = command
        self.format = format

        self.args = []

    def className( self ):
        return nameToClassName( self.command )

    def instanceVars( self ):
        result = []
        for typ, name in self.args:
            result.append( "    public %s %s;" % ( typ, name ) )
        return "\n".join( result )

    def regexp( self ):
        expression = ""
        for element in self.format:
            expression += self.rePart( element )
        return expression

    def translateSimpleType( self, typ, groupname ):
        if typ == "string":
            return """"?(?P<%s>[^"]*)"?""" % groupname
        elif typ == "int":
            return """(?P<%s>\d+)""" % groupname
        else:
            assert( False )

    def translateArgument( self, argument, optional = False ):
        typ, name = argument.split( ':' )
        assert( not optional )
        self.args.append( ( typ, name ) )
        return "%s" % self.translateSimpleType( typ, name )

    def rePart( self, part ):
        sys.stderr.write( "operating on %s" % part )
        if type( part ) == types.ListType:
            pass
        elif type( part ) == types.StringType:
            if part[0] == "<" and part[-1] == ">":
                return self.translateArgument( part[1:-1] )
            else:
                return part.replace( "+", "\+" ).replace( " ", "\ " )
        assert( False )

    def populateInstanceVars( self ):
        result = []
        for typ, name in self.args:
            result.append( """        %s = to_%s( "%s" );""" % ( name, typ, name ) )
        return "\n".join( result )

    def translate( self ):
        className = self.className()
        regexp = self.regexp()
        instanceVars = self.instanceVars()
        populateInstanceVars = self.populateInstanceVars()

        output = self.template % ( className,
                                   instanceVars,
                                   className,
                                   regexp,
                                   populateInstanceVars,
                                 )
        return output

#========================================================================#
class CommandWriter( object ):
#========================================================================#
    def __init__( self ):
        self.commands = {}

    def write( self, fileobj ):

        fileobj.write( """
namespace FsoGsm
{
""" )
        for key, value in commands.iteritems():
            ct = CommandTranslator( key, value )
            fileobj.write( ct.translate() )

        fileobj.write( """
public void registerGeneratedAtCommands( GLib.HashTable<string, AtCommand> table )
{
// register commands
""" )

        for key in commands:
            fileobj.write( """    table.insert( "%s", new FsoGsm.%s() );""" % ( nameToClassName( key ), nameToClassName( key ) ) )

        fileobj.write( """
}

} /* namespace FsoGsm */
""" )

#========================================================================#
if __name__ == "__main__":
#========================================================================#
    c = CommandWriter()
    c.write( sys.stdout )

