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

public void callback( HashTable<string, string> properties )
{
    debug( "got callback for subsystem '%s' with device path '%s'", properties.lookup( "SUBSYSTEM" ), properties.lookup( "DEVPATH" ) );
}

//===========================================================================
void test_kobjectnotifier_add_match()
//===========================================================================
{
    BaseKObjectNotifier.addMatch( "remove", "power_supply", callback );

    ( new MainLoop( null, false ) ).run();
}

//===========================================================================
void main( string[] args )
//===========================================================================
{
    Test.init( ref args );

    Test.add_func( "/KObjectNotifier/AddMatch", test_kobjectnotifier_add_match );

    Test.run();
}
