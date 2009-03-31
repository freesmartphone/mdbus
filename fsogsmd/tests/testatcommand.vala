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
void test_atcommand_PlusCGCLASS()
//===========================================================================
{
    FsoGsm.PlusCGCLASS cmd = (FsoGsm.PlusCGCLASS) atCommandFactory( "PlusCGCLASS" );
    cmd.parse( "+CGCLASS: \"A\"" );
    assert( cmd.gprsclass == "A" );
    cmd.parse( "+CGCLASS: A" );
    assert( cmd.gprsclass == "A" );
    try
    {
        cmd.parse( "PREFIX MISSING" );
        assert_not_reached();
    }
    catch ( Error e )
    {
    }
}

//===========================================================================
void test_atcommand_PlusCGMI()
//===========================================================================
{
    FsoGsm.PlusCGMI cmd = (FsoGsm.PlusCGMI) atCommandFactory( "PlusCGMI" );
    cmd.parse( "+CGMI: FIC/OpenMoko" );
    assert( cmd.manufacturer == "FIC/OpenMoko" );
    cmd.parse( "+CGMI: \"SIEMENS\"" );
    assert( cmd.manufacturer == "SIEMENS" );
    cmd.parse( "HTC" );
    assert( cmd.manufacturer == "HTC" );
}

//===========================================================================
void test_atcommand_PlusCGMM()
//===========================================================================
{
    FsoGsm.PlusCGMM cmd = (FsoGsm.PlusCGMM) atCommandFactory( "PlusCGMM" );
    cmd.parse( "+CGMM: \"Neo1973 GTA01/GTA02 Embedded GSM Modem\"" );
    assert( cmd.model == "Neo1973 GTA01/GTA02 Embedded GSM Modem" );
    cmd.parse( "+CGMM: SIEMENS" );
    assert( cmd.model == "SIEMENS" );
    cmd.parse( "HTC" );
    assert( cmd.model == "HTC" );
}

//===========================================================================
void test_atcommand_PlusCGMR()
//===========================================================================
{
    FsoGsm.PlusCGMR cmd = (FsoGsm.PlusCGMR) atCommandFactory( "PlusCGMR" );
    cmd.parse( "+CGMR: \"GSM: gsm_ac_gp_fd_pu_em_cph_ds_vc_cal35_ri_36_amd8_ts0-Moko11b1\"" );
    assert( cmd.revision == "GSM: gsm_ac_gp_fd_pu_em_cph_ds_vc_cal35_ri_36_amd8_ts0-Moko11b1" );
    cmd.parse( "+CGMR: SIEMENS" );
    assert( cmd.revision == "SIEMENS" );
    cmd.parse( "HTC" );
    assert( cmd.revision == "HTC" );
}

//===========================================================================
void test_atcommand_PlusCGSN()
//===========================================================================
{
    FsoGsm.PlusCGSN cmd = (FsoGsm.PlusCGSN) atCommandFactory( "PlusCGSN" );
    cmd.parse( "+CGSN: 1234567890" );
    assert( cmd.imei == "1234567890" );
    cmd.parse( "+CGSN: \"1234567890\"" );
    assert( cmd.imei == "1234567890" );
    cmd.parse( "1234567890" );
    assert( cmd.imei == "1234567890" );
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
void test_atcommand_PlusFCLASS()
//===========================================================================
{
    FsoGsm.PlusFCLASS cmd = (FsoGsm.PlusFCLASS) atCommandFactory( "PlusFCLASS" );
    cmd.parse( "0" );
    assert( cmd.faxclass == "0" );
    cmd.parse( "2.0" );
    assert( cmd.faxclass == "2.0" );
}

//===========================================================================
void main( string[] args )
//===========================================================================
{
    Test.init( ref args );

    Test.add_func( "/AtCommand/+CFUN", test_atcommand_PlusCFUN );
    Test.add_func( "/AtCommand/+CGCLASS", test_atcommand_PlusCGCLASS );
    Test.add_func( "/AtCommand/+CGMM", test_atcommand_PlusCGMM );
    Test.add_func( "/AtCommand/+CGMR", test_atcommand_PlusCGMR );
    Test.add_func( "/AtCommand/+CGSN", test_atcommand_PlusCGSN );
    Test.add_func( "/AtCommand/+CPIN", test_atcommand_PlusCPIN );
    Test.add_func( "/AtCommand/+FCLASS", test_atcommand_PlusFCLASS );
    Test.run();
}
