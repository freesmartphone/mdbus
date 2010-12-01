/**
 * Copyright (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
using FsoFramework;

const string TEST_FILE_NAME = "testsmartkeyfile.ini";

//===========================================================================
void test_smartkeyfile_all()
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
}

//===========================================================================
void test_masterkeyfile_all()
//===========================================================================
{
    var mkf = theMasterKeyFile();
}

//===========================================================================
void main (string[] args)
//===========================================================================
{
    Test.init (ref args);

    // SmartKeyFile creation

    Test.add_func ("/SmartKeyFile/all", test_smartkeyfile_all);
    Test.add_func ("/MasterKeyFile/all", test_masterkeyfile_all);

    Test.run ();
}
