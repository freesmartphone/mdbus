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
using Gee;
using FsoGsm;

HashMap<string,FsoGsm.AtCommand> commands;

void setup()
{
    commands = new HashMap<string,FsoGsm.AtCommand>();
    registerGenericAtCommands( commands );
}

AtCommand atCommandFactory( string command )
{
    assert( commands != null );
    AtCommand? cmd = commands[ command ];
    assert( cmd != null );
    return cmd;
}

//===========================================================================
void test_atcommand_PlusCFUN()
//===========================================================================
{
    FsoGsm.PlusCFUN cmd = (FsoGsm.PlusCFUN) atCommandFactory( "+CFUN" );
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
    FsoGsm.PlusCGCLASS cmd = (FsoGsm.PlusCGCLASS) atCommandFactory( "+CGCLASS" );

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
    FsoGsm.PlusCGMI cmd = (FsoGsm.PlusCGMI) atCommandFactory( "+CGMI" );

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
    FsoGsm.PlusCGMM cmd = (FsoGsm.PlusCGMM) atCommandFactory( "+CGMM" );

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
    FsoGsm.PlusCGMR cmd = (FsoGsm.PlusCGMR) atCommandFactory( "+CGMR" );

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
    FsoGsm.PlusCGSN cmd = (FsoGsm.PlusCGSN) atCommandFactory( "+CGSN" );
    cmd.parse( "+CGSN: 1234567890" );
    assert( cmd.imei == "1234567890" );

    cmd.parse( "+CGSN: \"1234567890\"" );
    assert( cmd.imei == "1234567890" );

    cmd.parse( "1234567890" );
    assert( cmd.imei == "1234567890" );
}

//===========================================================================
void test_atcommand_PlusCOPS()
//===========================================================================
{
    FsoGsm.PlusCOPS cmd = (FsoGsm.PlusCOPS) atCommandFactory( "+COPS" );
    cmd.parse( "+COPS: 2" );
    assert( cmd.status == 2 );
    assert( cmd.mode == -1 ); // not present
    assert( cmd.oper == null ); // not present

    cmd.parse( "+COPS: 0,3,\"E-Plus\"" );
    assert( cmd.status == 0 );
    assert( cmd.mode == 3 );
    assert( cmd.oper == "E-Plus" );
}

//===========================================================================
void test_atcommand_PlusCOPS_Test()
//===========================================================================
{
    FsoGsm.PlusCOPS_Test cmd = (FsoGsm.PlusCOPS_Test) atCommandFactory( "+COPS=?" );

    cmd.parse( """+COPS: (2,"E-Plus","E-Plus","26203"),(3,"Vodafone.de","Vodafone","26202"),(3,"T-Mobile D","TMO D","26201")""" );

    assert( cmd.info.length() == 3 );

    assert( cmd.info.nth_data(0).status == 2 );
    assert( cmd.info.nth_data(0).longname == "E-Plus" );
    assert( cmd.info.nth_data(0).shortname == "E-Plus" );
    assert( cmd.info.nth_data(0).mccmnc == "26203" );

    assert( cmd.info.nth_data(1).status == 3 );
    assert( cmd.info.nth_data(1).longname == "Vodafone.de" );
    assert( cmd.info.nth_data(1).shortname == "Vodafone" );
    assert( cmd.info.nth_data(1).mccmnc == "26202" );

    assert( cmd.info.nth_data(2).status == 3 );
    assert( cmd.info.nth_data(2).longname == "T-Mobile D" );
    assert( cmd.info.nth_data(2).shortname == "TMO D" );
    assert( cmd.info.nth_data(2).mccmnc == "26201" );
}

//===========================================================================
void test_atcommand_PlusCPIN()
//===========================================================================
{
    FsoGsm.PlusCPIN cmd = (FsoGsm.PlusCPIN) atCommandFactory( "+CPIN" );
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
    FsoGsm.PlusFCLASS cmd = (FsoGsm.PlusFCLASS) atCommandFactory( "+FCLASS" );
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

    setup();

    Test.add_func( "/AtCommand/+CFUN", test_atcommand_PlusCFUN );
    Test.add_func( "/AtCommand/+CGCLASS", test_atcommand_PlusCGCLASS );
    Test.add_func( "/AtCommand/+CGMM", test_atcommand_PlusCGMM );
    Test.add_func( "/AtCommand/+CGMR", test_atcommand_PlusCGMR );
    Test.add_func( "/AtCommand/+CGSN", test_atcommand_PlusCGSN );
    Test.add_func( "/AtCommand/+COPS?", test_atcommand_PlusCOPS );
    Test.add_func( "/AtCommand/+COPS=?", test_atcommand_PlusCOPS_Test );
    Test.add_func( "/AtCommand/+CPIN", test_atcommand_PlusCPIN );
    Test.add_func( "/AtCommand/+FCLASS", test_atcommand_PlusFCLASS );
    Test.run();
}
