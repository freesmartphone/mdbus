/**
 * Copyright (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

const string TEST_FILE_NAME = "testsmartkeyfile.ini";

//===========================================================================
void test_smartkeyfile_values()
//===========================================================================
{
    var smk = new SmartKeyFile();
    var ok = smk.loadFromFile( TEST_FILE_NAME );
    assert( ok );

    var stringvar = smk.stringValue( "section1", "keypresent", "defaultvalue" );
    assert ( stringvar == "present" );

    var stringvar2 = smk.stringValue( "section1", "notpresent", "defaultvalue" );
    assert ( stringvar2 == "defaultvalue" );

    var intvar = smk.intValue( "section2", "keypresent", 123456789 );
    assert ( intvar == 42 );

    var intvar2 = smk.intValue( "section2", "notpresent", 123456789 );
    assert ( intvar2 == 123456789 );

    var boolvar = smk.boolValue( "section3", "keypresent", false );
    assert ( boolvar );

    var boolvar2 = smk.boolValue( "section3", "notpresent", true );
    assert ( boolvar2 );

    var stringlistvar = smk.stringListValue( "section4", "keypresent", { "these", "values", "irrelevant" } );
    assert ( stringlistvar.length == 4 );
    assert ( stringlistvar[0] == "foo" );
    assert ( stringlistvar[1] == "bar" );
    assert ( stringlistvar[2] == "yo" );
    assert ( stringlistvar[3] == "kurt" );

    var stringlistvar2 = smk.stringListValue( "section4", "notpresent", { "these", "values", "default" } );
    assert ( stringlistvar2.length == 3 );
    assert ( stringlistvar2[0] == "these" );
    assert ( stringlistvar2[1] == "values" );
    assert ( stringlistvar2[2] == "default" );

    var stringlistvar3 = smk.stringListValue( "section4", "stillNotPresent" );
    assert ( stringlistvar3 == null );

}

//===========================================================================
void test_smartkeyfile_values_generics()
//===========================================================================
{

    var smk = new SmartKeyFile();
    var ok = smk.loadFromFile( TEST_FILE_NAME );
    assert( ok );

    /* enable when generics work again
    var stringvar = smk.getValue<string>( "section1", "keypresent", "defaultvalue" );
    assert ( stringvar == "present" );
    */

    var stringvar2 = smk.stringValue( "section1", "notpresent", "defaultvalue" );
    assert ( stringvar2 == "defaultvalue" );

    var intvar = smk.intValue( "section2", "keypresent", 123456789 );
    assert ( intvar == 42 );

    var intvar2 = smk.intValue( "section2", "notpresent", 123456789 );
    assert ( intvar2 == 123456789 );

    var boolvar = smk.boolValue( "section3", "keypresent", false );
    assert ( boolvar );

    var boolvar2 = smk.boolValue( "section3", "notpresent", true );
    assert ( boolvar2 );

    var stringlistvar = smk.stringListValue( "section4", "keypresent", { "these", "values", "irrelevant" } );
    assert ( stringlistvar.length == 4 );
    assert ( stringlistvar[0] == "foo" );
    assert ( stringlistvar[1] == "bar" );
    assert ( stringlistvar[2] == "yo" );
    assert ( stringlistvar[3] == "kurt" );

    var stringlistvar2 = smk.stringListValue( "section4", "notpresent", { "these", "values", "default" } );
    assert ( stringlistvar2.length == 3 );
    assert ( stringlistvar2[0] == "these" );
    assert ( stringlistvar2[1] == "values" );
    assert ( stringlistvar2[2] == "default" );

    var stringlistvar3 = smk.stringListValue( "section4", "stillNotPresent" );
    assert ( stringlistvar3 == null );
}

//===========================================================================
void test_smartkeyfile_sections()
//===========================================================================
{
    var smk = new SmartKeyFile();
    var ok = smk.loadFromFile( TEST_FILE_NAME );
    assert( ok );

    assert ( smk.hasSection( "section0" ) );
    assert ( !smk.hasSection( "this.section.not.there" ) );

    var sections = smk.sectionsWithPrefix();
    assert ( sections.length() == 9 );
    assert ( sections.nth_data(0) == "section0" );
    assert ( sections.nth_data(8) == "foo.bar" );

    var foosections = smk.sectionsWithPrefix( "foo" );
    foreach ( var section in foosections )
        assert ( section.has_prefix( "foo" ) );
    assert ( foosections.length() == 4 );
    assert ( foosections.nth_data(0) == "foo.1" );
    assert ( foosections.nth_data(3) == "foo.bar" );

    var nosections = smk.sectionsWithPrefix( "this.section.not.present" );
    assert ( nosections.length() == 0 );
}

//===========================================================================
void test_smartkeyfile_keys()
//===========================================================================
{
    var smk = new SmartKeyFile();
    var ok = smk.loadFromFile( TEST_FILE_NAME );
    assert( ok );

    assert ( smk.hasKey( "section1", "keypresent" ) );
    assert ( !smk.hasKey( "section.not.present", "this.key.not.there" ) );
    assert ( !smk.hasKey( "section1", "this.key.not.there" ) );

    var keys = smk.keysWithPrefix( "section4" );
    assert ( keys.length() == 5 );
    assert ( keys.nth_data(0) == "keypresent" );
    assert ( keys.nth_data(4) == "yo4" );

    var yokeys = smk.keysWithPrefix( "section4", "yo" );
    foreach ( var key in yokeys )
        assert ( key.has_prefix( "yo" ) );
    assert ( yokeys.length() == 4 );
    assert ( yokeys.nth_data(0) == "yo1" );
    assert ( yokeys.nth_data(3) == "yo4" );

    var nokeys = smk.keysWithPrefix( "this.key.not.present" );
    assert ( nokeys.length() == 0 );
}

//===========================================================================
void main (string[] args)
//===========================================================================
{
    Test.init (ref args);

    // SmartKeyFile creation

    Test.add_func ("/SmartKeyFile/Values", test_smartkeyfile_values);
    Test.add_func ("/SmartKeyFile/Values/Generics", test_smartkeyfile_values_generics);
    Test.add_func ("/SmartKeyFile/Sections", test_smartkeyfile_sections);
    Test.add_func ("/SmartKeyFile/Keys", test_smartkeyfile_keys);

    Test.run ();
}
