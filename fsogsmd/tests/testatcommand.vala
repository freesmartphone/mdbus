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
void test_atcommand_PlusCFUN()
//===========================================================================
{
    FsoGsm.PlusCFUN cmd = (FsoGsm.PlusCFUN) atCommandFactory( "PlusCFUN" );
    cmd.parse( "+CFUN: 0" );
    assert( cmd.fun == 0 );
    cmd.parse( "+CFUN: 1" );
    assert( cmd.fun == 1 );
    try
    {
        cmd.parse( "+CFUN: NOTANINTEGER" );
        assert_not_reached();
    }
    catch ( Error e )
    {
    }
}

//===========================================================================
void test_atcommand_PlusCPIN()
//===========================================================================
{
    FsoGsm.PlusCPIN cmd = (FsoGsm.PlusCPIN) atCommandFactory( "PlusCPIN" );
    cmd.parse( "+CPIN: \"SIM PIN\"" );
    assert( cmd.pin == "SIM PIN" );
    cmd.parse( "+CPIN: READY" );
    assert( cmd.pin == "READY" );
    try
    {
        cmd.parse( "+CPIN THIS FAILS" );
        assert_not_reached();
    }
    catch ( Error e )
    {
    }
}

//===========================================================================
void main( string[] args )
//===========================================================================
{
    Test.init( ref args );

    Test.add_func( "/AtCommand/+CPIN", test_atcommand_PlusCPIN );
    Test.add_func( "/AtCommand/+CFUN", test_atcommand_PlusCFUN );
    Test.run();
}
