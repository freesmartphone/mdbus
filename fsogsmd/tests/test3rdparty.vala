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
using FsoGsm;

public const string IMSI = "26203123456789";
public const string LONG_TEXT = """
            freesmartphone.org is a collaboration platform for open source and open discussion software projects working on interoperability and shared technology for Linux-based SmartPhones. freesmartphone.org works on a service layer (middleware) that allows developers to concentrate on their application business logic rather than dealing with device specifics. freesmartphone.org honours and bases on specifications and software created by the freedesktop.org community.""";
public const uint16 LONG_TEXT_REF = 42;

SList<weak Sms.Message*> smslist;

void test_sms_text_prepare()
{
    int offset;
    smslist = Sms.text_prepare( LONG_TEXT, LONG_TEXT_REF, true, out offset );
    message( "length=%u", smslist.length() );
}

void test_sms_assembly_new()
{
    var assembly = new Sms.Assembly( IMSI );
}

void test_sms_assembly_add()
{
    var assembly = new Sms.Assembly( IMSI );
    
}

//===========================================================================
void main( string[] args )
//===========================================================================
{
    Test.init( ref args );

    Test.add_func( "/3rdparty/Sms/TextPrepare", test_sms_text_prepare );

    Test.add_func( "/3rdparty/Sms/Assembly/New", test_sms_assembly_new );
    Test.add_func( "/3rdparty/Sms/Assembly/AddFragment", test_sms_assembly_add );

    Test.run();
}
