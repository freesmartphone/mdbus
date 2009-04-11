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

//===========================================================================
void test_commandqueue_enqueue()
//===========================================================================
{
    var transport = new FsoFramework.SerialTransport( "/tmp/fifo", 115200 );
    transport.open();
    assert( transport.isOpen() );

    var q = new AtCommandQueue( transport );

    /*
    var cmd = Command() { command = "AT+CGMR\r\n", handler = null };

    q.enqueue( cmd );

    transport.writeCallback( new IOChannel(), IOCondition.OUT ); // usually only called in mainloop
    */

}

//===========================================================================
void main( string[] args )
//===========================================================================
{
    Test.init( ref args );

    Test.add_func( "/CommandQueue/Enqueue", test_commandqueue_enqueue );
    Test.run();
}
