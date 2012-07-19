/**
 * Copyright (C) 2009-2012 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
using FsoGsm;

bool haveCommand = false;
bool expectedPrefix = false;

public bool hcf()
{
    return haveCommand;
}

public bool epf()
{
    return expectedPrefix;
}

string[] solicitedResponse;
string[] unsolicitedResponse;

public void soli( string[] response )
{
    assert( haveCommand );
    assert( solicitedResponse.length == response.length );
    for ( int i = 0; i < response.length; ++i )
    {
        debug( "line %d = '%s'", i, response[i] );
        assert( response[i] == solicitedResponse[i] );
    }
}

public void unsoli( string[] response )
{
    assert( !haveCommand || !expectedPrefix );
    assert( unsolicitedResponse.length == response.length );
    for ( int i = 0; i < response.length; ++i )
    {
        debug( "line %d = '%s'", i, response[i] );
        assert( response[i] == unsolicitedResponse[i] );
    }
}

//===========================================================================
void test_parser_1_solicited()
//===========================================================================
{
    FsoFramework.Parser parser = new StateBasedAtParser();
    parser.setDelegates( hcf, epf, soli, unsoli );

    haveCommand = true;
    expectedPrefix = false; // irrelevant for terminal lines
    solicitedResponse = { "OK" };
    unsolicitedResponse = {};
    parser.feed( "\r\nOK\r\n", 6 );
}

//===========================================================================
void test_parser_1_unsolicited()
//===========================================================================
{
    FsoFramework.Parser parser = new StateBasedAtParser();
    parser.setDelegates( hcf, epf, soli, unsoli );

    haveCommand = false;
    expectedPrefix = false;
    solicitedResponse = {};
    unsolicitedResponse = { "+FOO: Yo Kurt" };
    parser.feed( "\r\n+FOO: Yo Kurt\r\n", 17 );
}

//===========================================================================
void test_parser_2_solicited()
//===========================================================================
{
    FsoFramework.Parser parser = new StateBasedAtParser();
    parser.setDelegates( hcf, epf, soli, unsoli );

    haveCommand = true;
    expectedPrefix = true;
    solicitedResponse = { "+CPIN: \"READY\"", "OK" };
    unsolicitedResponse = {};
    parser.feed( "\r\n+CPIN: \"READY\"\r\n", 18 );
    parser.feed( "\r\nOK\r\n", 6 );
}

//===========================================================================
void test_parser_2_unsolicited()
//===========================================================================
{
    FsoFramework.Parser parser = new StateBasedAtParser();
    parser.setDelegates( hcf, epf, soli, unsoli );

    haveCommand = false;
    expectedPrefix = false;
    solicitedResponse = {};
    unsolicitedResponse = { "+FOO: Yo Kurt" };
    parser.feed( "\r\n+FOO: Yo Kurt\r\n", 17 );

    unsolicitedResponse = { "+BAR: Yo Kurt" };
    parser.feed( "\r\n+BAR: Yo Kurt\r\n", 17 );
}

//===========================================================================
void test_parser_2_unsolicited_pdu()
//===========================================================================
{
    FsoFramework.Parser parser = new StateBasedAtParser();
    parser.setDelegates( hcf, epf, soli, unsoli );

    haveCommand = false;
    expectedPrefix = false;
    solicitedResponse = {};
    unsolicitedResponse = { "+CMT: 120", "1234567890" };
    parser.feed( "\r\n+CMT: 120\r\n", 13 );
    parser.feed( "1234567890\r\n", 12 );
}

//===========================================================================
void test_parser_multiline_solicited()
//===========================================================================
{
    FsoFramework.Parser parser = new StateBasedAtParser();
    parser.setDelegates( hcf, epf, soli, unsoli );

    haveCommand = true;
    expectedPrefix = true;
    solicitedResponse = { "+FOO: 123456", "+BAR: 123456", "OK" };
    unsolicitedResponse = {};
    parser.feed( "\r\n+FOO: 123456", 14 );
    parser.feed( "\r\n+BAR: 123456", 14 );
    parser.feed( "\r\nOK\r\n", 6 );
}

//===========================================================================
void main( string[] args )
//===========================================================================
{
    Test.init( ref args );

    Test.add_func( "/Parser/1/Solicited", test_parser_1_solicited );
    Test.add_func( "/Parser/1/Unsolicited", test_parser_1_unsolicited );
    Test.add_func( "/Parser/2/Solicited", test_parser_2_solicited );
    Test.add_func( "/Parser/2/Unsolicited", test_parser_2_unsolicited );
    Test.add_func( "/Parser/2/Unsolicited/PDU", test_parser_2_unsolicited_pdu );
    Test.add_func( "/Parser/Multiline/Solicited", test_parser_multiline_solicited );

    Test.run();
}

// vim:ts=4:sw=4:expandtab
