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

void test_atresultparser_numbers()
{
    var prefix = "+CCFC:";
    var response = "+CCFC: 1111,2345,9";
    var num = 0;
    var parser = new AtResultParser( new string[] { response } );

    assert( parser.next( prefix ) );
    assert( parser.next_number( out num ) );
    assert( num == 1111 );
    assert( parser.next_number( out num ) );
    assert( num == 2345 );
    assert( parser.next_number( out num ) );
    assert( num == 9 );
}

void test_atresultparser_strings()
{
    var prefix = "+CCFC:";
    var response = "+CCFC: \"test12\",3,,\"test34\",testbla3";
    var str = "";
    var num = 0;
    var parser = new AtResultParser( new string[] { response } );

    assert( parser.next( prefix ) );
    assert( parser.next_string( out str ) );
    assert( str == "\"test12\"" );
    assert( parser.next_number( out num ) );
    assert( num == 3 );
    assert( parser.next_string( out str ) );
    assert( str == "" );
    assert( parser.next_string( out str ) );
    assert( str == "\"test34\"" );
    assert( parser.next_unquoted_string( out str ) );
    assert( str == "testbla3" );
}

void test_atresultparser_skip_next()
{
    var prefix = "+CCFC:";
    var response = "+CCFC: \"test12\",3,,\"test34\",testbla3";
    var str = "";
    var num = 0;
    var parser = new AtResultParser( new string[] { response } );

    assert( parser.next( prefix ) );
    assert( parser.skip_next() );
    assert( parser.next_number( out num ) );
    assert( num == 3 );
    assert( parser.skip_next() );
    assert( parser.skip_next() );
    assert( parser.next_unquoted_string( out str ) );
    assert( str == "testbla3" );
}

void test_atresultparser_list()
{
    var prefix = "+CCFC:";
    var response = "+CCFC: \"test12\",3,(\"test34\",testbla3)";
    var str = "";
    var num = 0;
    var parser = new AtResultParser( new string[] { response } );

    assert( parser.next( prefix ) );
    assert( parser.next_string( out str ) );
    assert( str == "\"test12\"" );
    assert( parser.next_number( out num ) );
    assert( num == 3 );
    assert( parser.open_list() );
    assert( parser.next_string( out str ) );
    assert( str == "\"test34\"" );
    assert( parser.next_unquoted_string( out str ) );
    assert( str == "testbla3" );
    assert( parser.close_list() );
}

void test_atresultparser_multiple_lines()
{
    var response0 = "+CCFC: \"test12\",3,(\"test34\",testbla3)";
     var response1 = "+CCLC: \"test32\",9,(\"test14\",testbla4)";
    var str = "";
    var num = 0;
    var parser = new AtResultParser( new string[] { response0, response1 } );

    assert( parser.next( "+CCFC:" ) );
    assert( !parser.next_number( out num ) );
    assert( parser.next_string( out str ) );
    assert( str == "\"test12\"" );
    assert( !parser.next_string( out str ) );
    assert( !parser.open_list() );
    assert( !parser.close_list() );
    assert( parser.next_number( out num ) );
    assert( num == 3 );
    assert( parser.open_list() );
    assert( parser.next_string( out str ) );
    assert( str == "\"test34\"" );
    assert( parser.next_unquoted_string( out str ) );
    assert( str == "testbla3" );
    assert( parser.close_list() );

    assert( parser.next( "+CCLC:" ) );
    assert( parser.next_string( out str ) );
    assert( str == "\"test32\"" );
    assert( parser.next_number( out num ) );
    assert( num == 9 );
    assert( parser.open_list() );
    assert( parser.next_string( out str ) );
    assert( str == "\"test14\"" );
    assert( parser.next_unquoted_string( out str ) );
    assert( str == "testbla4" );
    assert( parser.close_list() );

    assert( !parser.next( "+CCLC:" ) );

    parser = new AtResultParser( new string[] { response0, response1 } );
    assert( !parser.next( "+CCLC: +CCFC:" ) );
}

void main( string[] args )
{
    Test.init( ref args );
    Test.add_func( "/AtResultParser/Numbers", test_atresultparser_numbers );
    Test.add_func( "/AtResultParser/Strings", test_atresultparser_strings );
    Test.add_func( "/AtResultParser/SkipNext", test_atresultparser_skip_next );
    Test.add_func( "/AtResultParser/List", test_atresultparser_list );
    Test.add_func( "/AtResultParser/MultipleLInes", test_atresultparser_multiple_lines );
    Test.run();
}

// vim:ts=4:sw=4:expandtab
