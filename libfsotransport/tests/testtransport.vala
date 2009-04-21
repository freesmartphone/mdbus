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

const char[] TRANSPORT_TEST_STRING = "\r\n+DATA: FOO\r\n";
const char[] TRANSPORT_READ_STRING = "\r\n+CMS ERROR: YO KURT\r\n";

char[] buffer;
string readline;
bool gotHup;
bool frozen;

void transport_read_func( Transport transport )
{
    message( "read delegate called" );
    assert( !frozen );
    buffer = new char[512];
    var bytesread = transport.read( (void*)buffer, 512 );
    buffer[bytesread] = 0;
    readline = (string)buffer;
}

void transport_hup_func( Transport transport )
{
    message( "hup delegate called" );
    gotHup = true;
    transport.close();
}

//===========================================================================
void test_transport_base()
//===========================================================================
{
    var t = new BaseTransport( "testing" );
    TransportHupFunc hupfunc;
    TransportReadFunc readfunc;
//    t.getDelegates( out readfunc, out hupfunc );
//    assert( readfunc == null && hupfunc == null );

    t.setDelegates( transport_read_func, transport_hup_func );
//    t.getDelegates( out readfunc, out hupfunc );
//    assert( readfunc == read_func && hupfunc == hup_func );
}

//===========================================================================
void test_transport_serial()
//===========================================================================
{
    Posix.mkfifo( "./myfifo", Posix.S_IRUSR | Posix.S_IWUSR | Posix.S_IRGRP | Posix.S_IWGRP | Posix.S_IROTH | Posix.S_IWOTH );
    var t = new SerialTransport( "./myfifo", 115200 );
    t.open();
    assert( t.getName() == "./myfifo" );
    t.close();
    Posix.unlink( "./myfifo" );
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
void test_transport_pty_write()
//===========================================================================
{
    var t = new PtyTransport();
    t.open();
    t.write( TRANSPORT_TEST_STRING, TRANSPORT_TEST_STRING.length );

    // transport writes only from mainloop, so give time to do it
    var loop = new MainLoop( null, false );
    MainContext.default().iteration( false );

    var fd = Posix.open( t.getName(), Posix.O_RDONLY );
    assert( fd != -1 );
    var buf = new char[512];
    var length = Posix.read( fd, buf, 512 );
    buf[length] = 0;

    assert( length == TRANSPORT_TEST_STRING.length );
    assert( Memory.cmp( TRANSPORT_TEST_STRING, buf, TRANSPORT_TEST_STRING.length ) == 0 );

}

//===========================================================================
void test_transport_pty_read()
//===========================================================================
{
    readline = "";
    var t = new PtyTransport();
    t.setDelegates( transport_read_func, transport_hup_func );
    t.open();

    // open pts and write something to it, so the other side can pick it up
    var fd = Posix.open( t.getName(), Posix.O_RDWR );
    assert( fd != -1 );
    var written = Posix.write( fd, TRANSPORT_READ_STRING, TRANSPORT_READ_STRING.length );

    // transport reads only from mainloop, so give time to do it
    while ( readline == "" )
    {
        MainContext.default().iteration( false );
    }

    for( int i = 0; i < TRANSPORT_READ_STRING.length; ++i )
    {
        assert( readline[i] == TRANSPORT_READ_STRING[i] );
    }
}

//===========================================================================
void test_transport_pty_hup()
//===========================================================================
{
    gotHup = false;
    var t = new PtyTransport();
    t.setDelegates( transport_read_func, transport_hup_func );
    t.open();

    // open pts and close it again
    var fd = Posix.open( t.getName(), Posix.O_RDWR );
    assert( fd != -1 );
    Posix.close( fd );

    // transport should pick up a HUP change from within mainloop
    while ( !gotHup )
    {
        MainContext.default().iteration( false );
    }

    assert( !t.isOpen() );
}

//===========================================================================
void test_transport_pty_freeze_thaw()
//===========================================================================
{
    var t = new PtyTransport();
    t.setDelegates( transport_read_func, transport_hup_func );
    t.open();

    readline = "";

    // freeze transport
    t.freeze();
    frozen = true;

    // open pts and write something to it, so the other side can pick it up
    var fd = Posix.open( t.getName(), Posix.O_RDWR );
    assert( fd != -1 );
    var written = Posix.write( fd, "HELLO WORLD", 11 );

    // give time to pick up (which would be an error, since we're frozen)
    MainContext.default().iteration( false );
    MainContext.default().iteration( false );
    MainContext.default().iteration( false );

    // thaw transport
    frozen = false;
    t.thaw();

    // transport reads only from mainloop, so give time to do it
    while ( readline == "" )
    {
        MainContext.default().iteration( false );
    }

    assert( readline == "HELLO WORLD" );
}

//===========================================================================
void main( string[] args )
//===========================================================================
{
    Test.init( ref args );

    Test.add_func( "/Transport/Base/Create", test_transport_base );
    Test.add_func( "/Transport/Serial/OpenClose", test_transport_serial );
    Test.add_func( "/Transport/Pty/OpenClose", test_transport_pty );
    Test.add_func( "/Transport/Pty/Write", test_transport_pty_write );
    Test.add_func( "/Transport/Pty/Read", test_transport_pty_read );
    Test.add_func( "/Transport/Pty/Hup", test_transport_pty_hup );
    Test.add_func( "/Transport/Pty/FreezeThaw", test_transport_pty_freeze_thaw );

    Test.run();
}
