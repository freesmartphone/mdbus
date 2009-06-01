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
using FsoFramework;

//===========================================================================
void test_utilities_filehandling_presence()
//===========================================================================
{
    assert( FileHandling.isPresent( "this.file.not.present" ) == false );
    assert( FileHandling.isPresent( "textfile.txt" ) == true );
}

//===========================================================================
void test_utilities_filehandling_read()
//===========================================================================
{
    var contents = FileHandling.read( "textfile.txt" );
    assert( contents.has_prefix( "GNU" ) );
}

//===========================================================================
void test_utilities_filehandling_write()
//===========================================================================
{
    FileHandling.write( "Dieser Satz kein Verb!", "nocontent.txt" );
    var contents = FileHandling.read( "nocontent.txt" );
    assert( contents == "Dieser Satz kein Verb!" );
}

//===========================================================================
void test_utilities_stringhandling_list()
//===========================================================================
{
    string[] list = { "Dieser", "Satz", "kein", "Verb!" };
    var line = StringHandling.stringListToString( list );
    assert( line == "[ \"Dieser\", \"Satz\", \"kein\", \"Verb!\" ]" );
}

//===========================================================================
void test_utilities_network_ipv4address_for_interface()
//===========================================================================
{
    assert( Network.ipv4AddressForInterface( "lo" ) == "127.0.0.1" );
}

//===========================================================================
void main( string[] args )
//===========================================================================
{
    Test.init( ref args );

    Test.add_func( "/Utilities/FileHandling/Presence", test_utilities_filehandling_presence );
    Test.add_func( "/Utilities/FileHandling/Read", test_utilities_filehandling_read );
    Test.add_func( "/Utilities/FileHandling/Write", test_utilities_filehandling_write );
    Test.add_func( "/Utilities/StringHandling/List", test_utilities_stringhandling_list );
    Test.add_func( "/Utilities/Network/ipv4AddressForInterface", test_utilities_network_ipv4address_for_interface );

    Test.run();
}
