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

void test_atresultiter_numbers()
{
    var prefix = "+CCFC:";
    var response = "+CCFC: 1111,2345,9";
    var num = 0;
    var iter = new AtResultIter( new string[] { response } );

    assert( iter.next( prefix ) );
    assert( iter.next_number( out num ) );
    assert( num == 1111 );
    assert( iter.next_number( out num ) );
    assert( num == 2345 );
    assert( iter.next_number( out num ) );
    assert( num == 9 );
}

void test_atresultiter_strings()
{
    var prefix = "+CCFC:";
    var response = "+CCFC: \"test12\",3,,\"test34\",testbla3";
    var str = "";
    var num = 0;
    var iter = new AtResultIter( new string[] { response } );

    assert( iter.next( prefix ) );
    assert( iter.next_string( out str ) );
    assert( str == "\"test12\"" );
    assert( iter.next_number( out num ) );
    assert( num == 3 );
    assert( iter.next_string( out str ) );
    assert( str == "" );
    assert( iter.next_string( out str ) );
    assert( str == "\"test34\"" );
    assert( iter.next_unquoted_string( out str ) );
    assert( str == "testbla3" );
}

void test_atresultiter_skip_next()
{
    var prefix = "+CCFC:";
    var response = "+CCFC: \"test12\",3,,\"test34\",testbla3";
    var str = "";
    var num = 0;
    var iter = new AtResultIter( new string[] { response } );

    assert( iter.next( prefix ) );
    assert( iter.skip_next() );
    assert( iter.next_number( out num ) );
    assert( num == 3 );
    assert( iter.skip_next() );
    assert( iter.skip_next() );
    assert( iter.next_unquoted_string( out str ) );
    assert( str == "testbla3" );
}

void test_atresultiter_list()
{
    var prefix = "+CCFC:";
    var response = "+CCFC: \"test12\",3,(\"test34\",testbla3)";
    var str = "";
    var num = 0;
    var iter = new AtResultIter( new string[] { response } );

    assert( iter.next( prefix ) );
    assert( iter.next_string( out str ) );
    assert( str == "\"test12\"" );
    assert( iter.next_number( out num ) );
    assert( num == 3 );
    assert( iter.open_list() );
    assert( iter.next_string( out str ) );
    assert( str == "\"test34\"" );
    assert( iter.next_unquoted_string( out str ) );
    assert( str == "testbla3" );
    assert( iter.close_list() );
}

void test_atresultiter_multiple_lines()
{
    var response0 = "+CCFC: \"test12\",3,(\"test34\",testbla3)";
     var response1 = "+CCLC: \"test32\",9,(\"test14\",testbla4)";
    var str = "";
    var num = 0;
    var iter = new AtResultIter( new string[] { response0, response1 } );

    assert( iter.next( "+CCFC:" ) );
    assert( !iter.next_number( out num ) );
    assert( iter.next_string( out str ) );
    assert( str == "\"test12\"" );
    assert( !iter.next_string( out str ) );
    assert( !iter.open_list() );
    assert( !iter.close_list() );
    assert( iter.next_number( out num ) );
    assert( num == 3 );
    assert( iter.open_list() );
    assert( iter.next_string( out str ) );
    assert( str == "\"test34\"" );
    assert( iter.next_unquoted_string( out str ) );
    assert( str == "testbla3" );
    assert( iter.close_list() );

    assert( iter.next( "+CCLC:" ) );
    assert( iter.next_string( out str ) );
    assert( str == "\"test32\"" );
    assert( iter.next_number( out num ) );
    assert( num == 9 );
    assert( iter.open_list() );
    assert( iter.next_string( out str ) );
    assert( str == "\"test14\"" );
    assert( iter.next_unquoted_string( out str ) );
    assert( str == "testbla4" );
    assert( iter.close_list() );

    assert( !iter.next( "+CCLC:" ) );

    iter = new AtResultIter( new string[] { response0, response1 } );
    assert( !iter.next( "+CCLC: +CCFC:" ) );
}

void main( string[] args )
{
    Test.init( ref args );
    Test.add_func( "/AtResultIter/Numbers", test_atresultiter_numbers );
    Test.add_func( "/AtResultIter/Strings", test_atresultiter_strings );
    Test.add_func( "/AtResultIter/SkipNext", test_atresultiter_skip_next );
    Test.add_func( "/AtResultIter/List", test_atresultiter_list );
    Test.add_func( "/AtResultIter/MultipleLInes", test_atresultiter_multiple_lines );
    Test.run();
}

// vim:ts=4:sw=4:expandtab
