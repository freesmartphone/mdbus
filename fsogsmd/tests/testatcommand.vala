/**
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
using Gee;
using FsoGsm;
using FsoGsm.Constants;

HashMap<string,FsoGsm.AtCommand> commands;

void setup()
{
    // Take care we have a valid modem which is used by the commands to access it's logger
    // object
    FsoGsm.theModem = new FsoGsm.NullModem();

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
    assert( cmd.value == 0 );

    cmd.parse( "+CFUN: 1" );
    assert( cmd.value == 1 );

    try
    {
        cmd.parse( "+CFUN: NOTANINTEGER" );
        assert_not_reached();
    }
    catch ( Error e )
    {
    }

    var str = cmd.issue( 1 );
    assert( str == "+CFUN=1" );
}

//===========================================================================
void test_atcommand_PlusCGCLASS()
//===========================================================================
{
    FsoGsm.PlusCGCLASS cmd = (FsoGsm.PlusCGCLASS) atCommandFactory( "+CGCLASS" );

    cmd.parse( "+CGCLASS: \"A\"" );
    assert( cmd.value == "A" );

    cmd.parse( "+CGCLASS: A" );
    assert( cmd.value == "A" );

    try
    {
        cmd.parse( "PREFIX MISSING" );
        assert_not_reached();
    }
    catch ( Error e )
    {
    }

    var str = cmd.issue( "BX" );
    assert( str == "+CGCLASS=\"BX\"" );
}

//===========================================================================
void test_atcommand_PlusCGMI()
//===========================================================================
{
    FsoGsm.PlusCGMI cmd = (FsoGsm.PlusCGMI) atCommandFactory( "+CGMI" );

    cmd.parse( "+CGMI: FIC/OpenMoko" );
    assert( cmd.value == "FIC/OpenMoko" );

    cmd.parse( "+CGMI: \"SIEMENS\"" );
    assert( cmd.value == "SIEMENS" );

    cmd.parse( "HTC" );
    assert( cmd.value == "HTC" );
}

//===========================================================================
void test_atcommand_PlusCGMM()
//===========================================================================
{
    FsoGsm.PlusCGMM cmd = (FsoGsm.PlusCGMM) atCommandFactory( "+CGMM" );

    cmd.parse( "+CGMM: \"Neo1973 GTA01/GTA02 Embedded GSM Modem\"" );
    assert( cmd.value == "Neo1973 GTA01/GTA02 Embedded GSM Modem" );

    cmd.parse( "+CGMM: SIEMENS" );
    assert( cmd.value == "SIEMENS" );

    cmd.parse( "HTC" );
    assert( cmd.value == "HTC" );
}

//===========================================================================
void test_atcommand_PlusCGMR()
//===========================================================================
{
    FsoGsm.PlusCGMR cmd = (FsoGsm.PlusCGMR) atCommandFactory( "+CGMR" );

    cmd.parse( "+CGMR: \"GSM: gsm_ac_gp_fd_pu_em_cph_ds_vc_cal35_ri_36_amd8_ts0-Moko11b1\"" );
    assert( cmd.value == "GSM: gsm_ac_gp_fd_pu_em_cph_ds_vc_cal35_ri_36_amd8_ts0-Moko11b1" );

    cmd.parse( "+CGMR: SIEMENS" );
    assert( cmd.value == "SIEMENS" );

    cmd.parse( "HTC" );
    assert( cmd.value == "HTC" );
}

//===========================================================================
void test_atcommand_PlusCGSN()
//===========================================================================
{
    FsoGsm.PlusCGSN cmd = (FsoGsm.PlusCGSN) atCommandFactory( "+CGSN" );
    cmd.parse( "+CGSN: 1234567890" );
    assert( cmd.value == "1234567890" );

    cmd.parse( "+CGSN: \"1234567890\"" );
    assert( cmd.value == "1234567890" );

    cmd.parse( "1234567890" );
    assert( cmd.value == "1234567890" );
}

//===========================================================================
void test_atcommand_PlusCOPS()
//===========================================================================
{
    FsoGsm.PlusCOPS cmd = (FsoGsm.PlusCOPS) atCommandFactory( "+COPS" );
    cmd.parse( "+COPS: 2" );
    assert( cmd.mode == 2 );
    assert( cmd.format == -1 );
    assert( cmd.oper == "" ); // not present

    cmd.parse( "+COPS: 0,3,\"E-Plus\"" );
    assert( cmd.mode == 0 );
    assert( cmd.format == 3 );
    assert( cmd.oper == "E-Plus" );

    cmd.parseTest( """+COPS: (1,"E-Plus","E-Plus","26203"),(2,"Vodafone.de","Vodafone","26202",2),(3,"T-Mobile D","TMO D","26201")""" );
    assert( cmd.providers.length == 3 );

    assert( cmd.providers[0].status == "available" );
    assert( cmd.providers[0].longname == "E-Plus" );
    assert( cmd.providers[0].shortname == "E-Plus" );
    assert( cmd.providers[0].mccmnc == "26203" );
    assert( cmd.providers[0].act == "GSM" );

    assert( cmd.providers[1].status == "current" );
    assert( cmd.providers[1].longname == "Vodafone.de" );
    assert( cmd.providers[1].shortname == "Vodafone" );
    assert( cmd.providers[1].mccmnc == "26202" );
    assert( cmd.providers[1].act == "UMTS" );

    assert( cmd.providers[2].status == "forbidden" );
    assert( cmd.providers[2].longname == "T-Mobile D" );
    assert( cmd.providers[2].shortname == "TMO D" );
    assert( cmd.providers[2].mccmnc == "26201" );
    assert( cmd.providers[2].act == "GSM" );
}

//===========================================================================
void test_atcommand_PlusCPIN()
//===========================================================================
{
    FsoGsm.PlusCPIN cmd = (FsoGsm.PlusCPIN) atCommandFactory( "+CPIN" );
    cmd.parse( "+CPIN: \"SIM PIN\"" );
    assert( cmd.status == FreeSmartphone.GSM.SIMAuthStatus.PIN_REQUIRED );
    cmd.parse( "+CPIN: READY" );
    assert( cmd.status == FreeSmartphone.GSM.SIMAuthStatus.READY );
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
    assert( cmd.value == "0" );
    cmd.parse( "2.0" );
    assert( cmd.value == "2.0" );
}

//===========================================================================
void test_atcommand_PlusVTS()
//===========================================================================
{
    FsoGsm.PlusVTS cmd = (FsoGsm.PlusVTS) atCommandFactory( "+VTS" );
    assert( cmd.issue( "9AD0") == "+VTS=9;+VTS=A;+VTS=D;+VTS=0" );
    assert( cmd.issue( "B" ) == "+VTS=B" );
}

//===========================================================================
void test_atcommand_PlusCCFC()
//===========================================================================
{
    FsoGsm.PlusCCFC cmd = (FsoGsm.PlusCCFC) atCommandFactory( "+CCFC" );

    assert( cmd.query( FsoGsm.Constants.CallForwardingType.UNCONDITIONAL ) == "+CCFC=0,2" );
    assert( cmd.query( FsoGsm.Constants.CallForwardingType.ALL_CONDITIONAL,
                       FsoGsm.Constants.BearerClass.SMS ) == "+CCFC=5,2,,,8" );

    assert( cmd.issue( FsoGsm.Constants.CallForwardingMode.QUERY_STATUS,
                       FsoGsm.Constants.CallForwardingType.ALL_CONDITIONAL ) == "+CCFC=5,2" );
    assert( cmd.issue( FsoGsm.Constants.CallForwardingMode.ENABLE,
                       FsoGsm.Constants.CallForwardingType.BUSY,
                       FsoGsm.Constants.BearerClass.SMS ) == "+CCFC=1,1,,,8" );

    assert( cmd.issue_ext( FsoGsm.Constants.CallForwardingMode.REGISTRATION,
                           FsoGsm.Constants.CallForwardingType.UNCONDITIONAL,
                           FsoGsm.Constants.BearerClass.SMS,
                           "+49123456789", 100 ) == "+CCFC=0,3,\"+49123456789\",145,8" );
    assert( cmd.issue_ext( FsoGsm.Constants.CallForwardingMode.REGISTRATION,
                           FsoGsm.Constants.CallForwardingType.NO_REPLY,
                           FsoGsm.Constants.BearerClass.SMS,
                           "+49123456789", 100 ) == "+CCFC=2,3,\"+49123456789\",145,8,,,100" );

    try
    {
        cmd.parseMulti( new string[] {
            "+CCFC: 1,7",
            "+CCFC: 1,1,\"+49123456789\",143,,,50",
            "+CCFC: 0,8,\"+491234567890\",143,\"987654321\",128,40"
        } );

        assert( cmd.conditions.length() == 3 );

        var n = 0;
        foreach ( var condition in cmd.conditions )
        {
            if ( n == 0 )
            {
                assert( condition.status == CallForwardingStatus.ACTIVE );
                assert( condition.cls == BearerClass.DEFAULT );
                assert( condition.number == "" );
                assert( condition.time == 20 );
            }
            else if ( n == 1 )
            {
                assert( condition.status == CallForwardingStatus.ACTIVE );
                assert( condition.cls == BearerClass.VOICE );
                assert( condition.number == "+49123456789" );
                assert( condition.time == 50 );
            }
            else if ( n == 2 )
            {
                assert( condition.status == CallForwardingStatus.NOT_ACTIVE );
                assert( condition.cls == BearerClass.SMS );
                assert( condition.number == "+491234567890" );
                assert( condition.time == 40 );
            }

            n++;
        }
    }
    catch ( Error e )
    {
        assert_not_reached();
    }
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
    Test.add_func( "/AtCommand/+COPS", test_atcommand_PlusCOPS );
    Test.add_func( "/AtCommand/+CPIN", test_atcommand_PlusCPIN );
    Test.add_func( "/AtCommand/+FCLASS", test_atcommand_PlusFCLASS );
    Test.add_func( "/AtCommand/+VTS", test_atcommand_PlusVTS );
    Test.add_func( "/AtCommand/+CCFC", test_atcommand_PlusCCFC );
    Test.run();
}

// vim:ts=4:sw=4:expandtab
