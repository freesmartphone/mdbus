/**
 * Copyright (C) 2012 Simon Busch <morphis@gravedo.de>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 */

using GLib;
using Gee;
using FsoGsm;

void test_simpleatcommandsequence_create()
{
    var seq = new SimpleAtCommandSequence( { } );
    assert( seq.commands.length == 0 );

    seq = new SimpleAtCommandSequence( { "E0Q0V1", "+CMEE=1", "+CRC=1" } );
    assert( seq.commands.length == 3 );
    assert( seq.commands[0] == "E0Q0V1" );
    assert( seq.commands[1] == "+CMEE=1" );
    assert( seq.commands[2] == "+CRC=1" );
}

void test_simpleatcommandsequence_merge()
{
    var seq0 = new SimpleAtCommandSequence( { "E0Q0V1", "+CMEE=1", "+CRC=1" } );
    var seq1 =  new SimpleAtCommandSequence.merge( seq0, { "+CSNS=0", "+CCWA=0" } );

    assert( seq1.commands.length == 5 );
    assert( seq1.commands[0] == "E0Q0V1" );
    assert( seq1.commands[1] == "+CMEE=1" );
    assert( seq1.commands[2] == "+CRC=1" );
    assert( seq1.commands[3] == "+CSNS=0" );
    assert( seq1.commands[4] == "+CCWA=0" );
}

void main( string[] args )
{
    Test.init( ref args );
    Test.add_func( "/SimpleAtCommandSequence/Create", test_simpleatcommandsequence_create );
    Test.add_func( "/SimpleAtCommandSequence/Merge", test_simpleatcommandsequence_merge );
    Test.run();
}

// vim:ts=4:sw=4:expandtab
