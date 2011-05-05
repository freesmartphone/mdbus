/*
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

MainLoop loop;

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
void test_utilities_filehandling_remove_tree()
//===========================================================================
{
    assert( !FileHandling.removeTree( "this_tree_not_existing" ) );
    DirUtils.create_with_parents( "./this/tree/existing", 0777 );
    assert( FileHandling.removeTree( "this" ) );
}

//===========================================================================
void test_utilities_stringhandling_list()
//===========================================================================
{
    string[] list = { "Dieser", "Satz", "kein", "Verb!" };
    var line = StringHandling.stringListToString( list );
    assert( line == "[ \"Dieser\", \"Satz\", \"kein\", \"Verb!\" ]" );
}

public enum MyEnumType { FOO, BAR, BAZ }
public enum MyEnumType2 { FOO, BAR, BAZ }

//===========================================================================
void test_utilities_stringhandling_enum()
//===========================================================================
{
    assert ( StringHandling.enumToString<MyEnumType>( MyEnumType.FOO ) == "MY_ENUM_TYPE_FOO" );
    assert ( StringHandling.enumToString<MyEnumType>( MyEnumType.BAR ) == "MY_ENUM_TYPE_BAR" );
    assert ( StringHandling.enumToString<MyEnumType>( MyEnumType.BAZ ) == "MY_ENUM_TYPE_BAZ" );
    assert ( StringHandling.enumToString<MyEnumType>( (MyEnumType)1000 ).has_prefix( "Unknown" ) );
    assert ( StringHandling.convertEnum<MyEnumType, MyEnumType2>( MyEnumType.BAR ) == MyEnumType2.BAR );
    assert ( StringHandling.enumFromName<MyEnumType>( "MY_ENUM_TYPE_FOO" ) == MyEnumType.FOO );
    assert ( StringHandling.enumToNick( MyEnumType.FOO ) == "foo" );
    assert ( StringHandling.enumFromNick<MyEnumType>( "foo" ) == MyEnumType.FOO );
    assert ( StringHandling.enumFromString<MyEnumType>( "foobar", MyEnumType.FOO ) == MyEnumType.FOO );
    assert ( StringHandling.enumFromString<MyEnumType>( "bar", MyEnumType.FOO ) == MyEnumType.BAR );
    assert ( StringHandling.enumFromString<MyEnumType>( "MY_ENUM_TYPE_BAR", MyEnumType.FOO ) == MyEnumType.BAR );
}

//===========================================================================
void test_utilities_stringhandling_key_value_split()
//===========================================================================
{
    var result = StringHandling.splitKeyValuePairs( "" );
    assert( result.size() == 0 );

    result = StringHandling.splitKeyValuePairs( "YoKurt Nix Nix" );
    assert( result.size() == 0 );

    result = StringHandling.splitKeyValuePairs( "FOO=BAR" );
    assert( result.size() == 1 );
    assert( result.lookup( "FOO" ) == "BAR" );

    result = StringHandling.splitKeyValuePairs( "prefix\nFOO=BAR\nBOO=FAZ\npostfix" );
    assert( result.size() == 2 );
    assert( result.lookup( "FOO" ) == "BAR" );
    assert( result.lookup( "BOO" ) == "FAZ" );
}

//===========================================================================
void test_utilities_stringhandling_filter_by_allowed_characters()
//===========================================================================
{
    var result = StringHandling.filterByAllowedCharacters( "(0) 69-243 448", "+0123456789wp" );
    assert( result == "069243448" );
}

//===========================================================================
void test_utilities_utility_program_name()
//===========================================================================
{
    assert( Utility.programName().has_suffix( "lt-testutilities" ) );
}

//===========================================================================
void test_utilities_utility_prefix_for_executable()
//===========================================================================
{
    assert( Utility.prefixForExecutable().has_suffix( "lt-testutilities/" ) );
}

//===========================================================================
void test_utilities_utility_first_available_program()
//===========================================================================
{
    assert( Utility.firstAvailableProgram( { "foo", "bar", "yo", "kurt" } ) == null );
    assert( Utility.firstAvailableProgram( { "bash", "dash", "ash" } ) == "/bin/bash" );
}

//===========================================================================
void test_utilities_utility_create_backtrace()
//===========================================================================
{
    var backtrace = Utility.createBacktrace();
    assert( backtrace.length > 2 );
}

//===========================================================================
void test_utilities_utility_hardware()
//===========================================================================
{
    var hardware = Utility.hardware();
    assert( hardware == "default" );
}

//===========================================================================
async void foo()
{
    var text = yield Network.textForUri( "checkip.dyndns.org", "/" );
    loop.quit();
}

void test_utilities_network_textForUri()
//===========================================================================
{
    loop = new MainLoop();
    Idle.add( () => { foo(); return false; } );
    loop.run();
}

//===========================================================================
void main( string[] args )
//===========================================================================
{
    Test.init( ref args );

    Test.add_func( "/Utilities/FileHandling/Presence", test_utilities_filehandling_presence );
    Test.add_func( "/Utilities/FileHandling/Read", test_utilities_filehandling_read );
    Test.add_func( "/Utilities/FileHandling/Write", test_utilities_filehandling_write );
    Test.add_func( "/Utilities/FileHandling/RemoveTree", test_utilities_filehandling_remove_tree );
    Test.add_func( "/Utilities/StringHandling/List", test_utilities_stringhandling_list );
    Test.add_func( "/Utilities/StringHandling/Enum", test_utilities_stringhandling_enum );
    Test.add_func( "/Utilities/StringHandling/Split", test_utilities_stringhandling_key_value_split );
    Test.add_func( "/Utilities/StringHandling/Filter", test_utilities_stringhandling_filter_by_allowed_characters );
    Test.add_func( "/Utilities/Utility/programName", test_utilities_utility_program_name );
    Test.add_func( "/Utilities/Utility/prefixForExecutable", test_utilities_utility_prefix_for_executable );
    Test.add_func( "/Utilities/Utility/firstAvailableProgram", test_utilities_utility_first_available_program );
    Test.add_func( "/Utilities/Utility/createBacktrace", test_utilities_utility_create_backtrace );
    Test.add_func( "/Utilities/Utility/hardware", test_utilities_utility_hardware );
    Test.add_func( "/Utilities/Network/textForUri", test_utilities_network_textForUri );

    Test.run();
}

// vim:ts=4:sw=4:expandtab
