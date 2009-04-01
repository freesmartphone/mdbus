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
void test_transport_base()
//===========================================================================
{
    var t = new BaseTransport( "testing" );
}

//===========================================================================
void test_transport_serial()
//===========================================================================
{
    var t = new SerialTransport( "/dev/tty0", 115200 );
    t.open();
    assert( t.getName() == "/dev/tty0" );
    t.close();
}

//===========================================================================
void test_transport_pty()
//===========================================================================
{
    var t1 = new PtyTransport();
    t1.open();
    var name1 = t1.getName();
    assert( name1.has_prefix( "/dev/pts/" ) );

    var t2 = new PtyTransport();
    t2.open();
    var name2 = t2.getName();
    assert( name2.has_prefix( "/dev/pts/" ) );
    assert( name1 != name2 );

    t2.close();
    t1.close();
}

//===========================================================================
void main( string[] args )
//===========================================================================
{
    Test.init( ref args );

    Test.add_func( "/Transport/Base/Create", test_transport_base );
    Test.add_func( "/Transport/Serial/OpenClose", test_transport_serial );
    Test.add_func( "/Transport/Pty/OpenClose", test_transport_pty );

    Test.run();
}
