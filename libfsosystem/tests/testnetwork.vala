/*
 * Copyright (C) 2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

//===========================================================================
void test_network_interface_updown()
{
    try
    {
        var iface = new FsoFramework.Network.Interface( "eth0" );

        if ( iface.is_up() )
        {
            iface.down();
            assert( !iface.is_up() );
        }
        else
        {
            iface.up();
            assert( iface.is_up() );
        }
    }
    catch ( Error err )
    {
        error( @"test_network_interface_updown failed: $(err.message)" );
    }
}

//===========================================================================
void main( string[] args )
//===========================================================================
{
    Test.init( ref args );

    Test.add_func( "/Network/Interface/UpDown", test_network_interface_updown );

    Test.run();
}

// vim:ts=4:sw=4:expandtab
