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

/**
 * This file contains AT command specifications defined the official 3GPP GSM
 * specifications, such as 05.05 and 07.07.
 *
 * Do _not_ add vendor-specific commands here, instead add them to your modem plugin.
 **/

using Gee;

namespace FsoGsm {

public class PlusCALA : AbstractAtCommand
{
    public int year;
    public int month;
    public int day;
    public int hour;
    public int minute;
    public int second;
    public int tzoffset;

    public PlusCALA()
    {
        // some modems strip the leading zero for one-digit chars

        var str = """\+CALA: "?(?P<year>\d?\d)/(?P<month>\d?\d)/(?P<day>\d?\d),(?P<hour>\d?\d):(?P<minute>\d?\d):(?P<second>\d?\d)(?:[\+-](?P<tzoffset>\d\d))?"?,0,0,""";
        str += "\"(?P<mccmnc>[^\"]*)\"";
        re = new Regex( str );
        prefix = { "+CALA: " };
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        year = to_int( "year" );
        month = to_int( "month" );
        day = to_int( "day" );
        hour = to_int( "hour" );
        minute = to_int( "minute" );
        second = to_int( "second" );
        tzoffset = to_int( "tzoffset" );
    }

    public string issue( int year, int month, int day, int hour, int minute, int second, int tzoffset )
    {
        //FIXME: check whether only some modems do not like the timezone parameter
        return "+CALA=\"%02d/%02d/%02d,%02d:%02d:%02d\",0,0,\"Dr.Mickey rocks!\"".printf( year, month, day, hour, minute, second );
    }

    public string clear()
    {
        return "+CALA=\"\"";
    }

    public string query()
    {
        return "+CALA?";
    }
}

public class PlusCBC : AbstractAtCommand
{
    public string status;
    public int level;

    public PlusCBC()
    {
        re = new Regex( """\+CBC: (?P<status>\d),(?P<level>\d+)""" );
        prefix = { "+CBC: " };
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        status = Constants.instance().devicePowerStatusToString( to_int( "status" ) );
        level = to_int( "level" );
    }

    public string execute()
    {
        return "+CBC";
    }
}

public class PlusCCLK : AbstractAtCommand
{
    public int year;
    public int month;
    public int day;
    public int hour;
    public int minute;
    public int second;
    public int tzoffset;

    public PlusCCLK()
    {
        // some modems strip the leading zero for one-digit chars
        re = new Regex( """\+CCLK: "?(?P<year>\d?\d)/(?P<month>\d?\d)/(?P<day>\d?\d),(?P<hour>\d?\d):(?P<minute>\d?\d):(?P<second>\d?\d)(?:[\+-](?P<tzoffset>\d\d))?"?""" );
        prefix = { "+CCLK: " };
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        year = to_int( "year" );
        month = to_int( "month" );
        day = to_int( "day" );
        hour = to_int( "hour" );
        minute = to_int( "minute" );
        second = to_int( "second" );
        tzoffset = to_int( "tzoffset" );
    }

    public string issue( int year, int month, int day, int hour, int minute, int second, int tzoffset )
    {
        //FIXME: check whether only some modems do not like the timezone parameter
        //return "+CCLK=\"%02d/%02d/%02d,%02d:%02d:%02d+%02d\"".printf( year, month, day, hour, minute, second, tzoffset );
        return "+CCLK=\"%02d/%02d/%02d,%02d:%02d:%02d\"".printf( year, month, day, hour, minute, second );
    }

    public string query()
    {
        return "+CCLK?";
    }
}

public class PlusCFUN : SimpleAtCommand<int>
{
    public PlusCFUN()
    {
        base( "+CFUN" );
    }
}

public class PlusCGCLASS : SimpleAtCommand<string>
{
    public PlusCGCLASS()
    {
        base( "+CGCLASS" );
    }
}

public class PlusCGMI : SimpleAtCommand<string>
{
    public PlusCGMI()
    {
        base( "+CGMI", true );
    }
}

public class PlusCGMM : SimpleAtCommand<string>
{
    public PlusCGMM()
    {
        base( "+CGMM", true );
    }
}

public class PlusCGMR : SimpleAtCommand<string>
{
    public PlusCGMR()
    {
        base( "+CGMR", true );
    }
}

public class PlusCGSN : SimpleAtCommand<string>
{
    public PlusCGSN()
    {
        base( "+CGSN", true );
    }
}

public class PlusCLVL : SimpleAtCommand<int>
{
    public PlusCLVL()
    {
        base( "+CLVL" );
    }
}

public class PlusCNMI : AbstractAtCommand
{
    public int mode;
    public int mt;
    public int bm;
    public int ds;
    public int bfr;

    public PlusCNMI()
    {
        re = new Regex( """\+CNMI: (?P<mode>\d),(?P<mt>\d),(?P<bm>\d),(?P<ds>\d),(?P<bfr>\d)""" );
        prefix = { "+CNMI: " };
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        mode = to_int( "mode" );
        mt = to_int( "mt" );
        bm = to_int( "bm" );
        ds = to_int( "ds" );
        bfr = to_int( "bfr" );
    }

    public string query()
    {
        return "+CNMI?";
    }

    public string issue( int mode, int mt, int bm, int ds, int bfr )
    {
        return "+CNMI=%d,%d,%d,%d,%d".printf( mode, mt, bm, ds, bfr );
    }
}

public class PlusCMICKEY : SimpleAtCommand<int>
{
    public PlusCMICKEY()
    {
        base( "+CMICKEY" );
    }
}

public class PlusCMUT : SimpleAtCommand<int>
{
    public PlusCMUT()
    {
        base( "+CMUT" );
    }
}

public class PlusCOPS : AbstractAtCommand
{
    public int status;
    public int mode;
    public string oper;

    public FreeSmartphone.GSM.NetworkProvider[] providers;

    public PlusCOPS()
    {
        re = new Regex( """\+COPS:\ (?P<status>\d)(,(?P<mode>\d)?(,"(?P<oper>[^"]*)")?)?""" );
        tere = new Regex( """\((?P<status>\d),"(?P<longname>[^"]*)","(?P<shortname>[^"]*)","(?P<mccmnc>[^"]*)"(?:,(?P<act>\d))?\)""" );
        prefix = { "+COPS: " };
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        status = to_int( "status" );
        mode = to_int( "mode" );
        oper = to_string( "oper" );
    }

    public override void parseTest( string response ) throws AtCommandError
    {
        base.parse( response );
        var providers = new FreeSmartphone.GSM.NetworkProvider[] {};
        do
        {
            var p = FreeSmartphone.GSM.NetworkProvider() {
                status = Constants.instance().networkProviderStatusToString( to_int( "status" ) ),
                longname = to_string( "longname" ),
                shortname = to_string( "shortname" ),
                mccmnc = to_string( "mccmnc" ),
                act = Constants.instance().networkProviderActToString( to_int( "act" ) ) };
            providers += p;
        }
        while ( mi.next() );
        this.providers = providers;
    }

    public string issue( int mode, int format, int oper = 0 )
    {
        if ( oper == 0 )
            return "+COPS=%d,%d".printf( mode, format );
        else
            return "+COPS=%d,%d,\"%d\"".printf( mode, format, oper );
    }

    public string query()
    {
        return "+COPS?";
    }

    public string test()
    {
        return "+COPS=?";
    }
}

public class PlusCPBR : AbstractAtCommand
{
    public int min;
    public int max;

    public FreeSmartphone.GSM.SIMEntry[] phonebook;

    public PlusCPBR()
    {
        re = new Regex( """\+CPBR: (?P<id>\d+),"(?P<number>[\+0-9*#w]+)",(?P<typ>\d+),"(?P<name>[^"]*)"""" );
        tere = new Regex( """\+CPBR: \((?P<min>\d+)-(?P<max>\d+)\),\d+,\d+""" );
        prefix = { "+CPBR: " };
    }

    public void parseMulti( string[] response ) throws AtCommandError
    {
        var phonebook = new FreeSmartphone.GSM.SIMEntry[] {};
        foreach ( var line in response )
        {
            base.parse( line );
            var entry = FreeSmartphone.GSM.SIMEntry() {
                index = to_int( "id" ),
                number = to_string( "number" ),
                name = to_string( "name" )
            };
            phonebook += entry;
        }
        this.phonebook = phonebook;
    }

    public override void parseTest( string response ) throws AtCommandError
    {
        base.parseTest( response );
        min = to_int( "min" );
        max = to_int( "max" );
    }

    public string issue( string cat, int first, int last )
    {
        //return @"+CPBS=\"$cat\";+CPBR=$first,$last";
        return """+CPBS="%s";+CPBR=%d,%d""".printf( cat, first, last );
    }

    public string test( string cat )
    {
        //return @"+CPBS=\"%cat\";+CPBR=?";
        return """+CPBS="%s";+CPBR=?""".printf( cat );
    }
}

public class PlusCPBS : AbstractAtCommand
{
    public string[] phonebooks;

    public PlusCPBS()
    {
        tere = new Regex( """\"(?P<book>[A-Z][A-Z])\"""" );
        prefix = { "+CPBS: " };
    }

    public override void parseTest( string response ) throws AtCommandError
    {
        base.parseTest( response );
        var books = new string[] {};
        do
        {
            books += Constants.instance().simPhonebookNameToString( to_string( "book" ) );
            message( "adding book %s", Constants.instance().simPhonebookNameToString( to_string( "book" ) ) );
        }
        while ( mi.next() );
        phonebooks = books;
    }

    public string test()
    {
        return "+CPBS=?";
    }
}

public class PlusCPIN : AbstractAtCommand
{
    public string pin;

    public PlusCPIN()
    {
        re = new Regex( """\+CPIN:\ "?(?P<pin>[^"]*)"?""" );
        prefix = { "+CPIN: " };
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        pin = to_string( "pin" );
    }

    public string issue( string pin, string? new_pin = null )
    {
        if ( new_pin == null )
            return "+CPIN=\"%s\"".printf( pin );
        else
            return "+CPIN=\"%s\",\"%s\"".printf( pin, new_pin );
    }

    public string query()
    {
        return "+CPIN?";
    }
}

public class PlusFCLASS : AbstractAtCommand
{
    public string faxclass;

    public PlusFCLASS()
    {
        re = new Regex( """"?(?P<faxclass>[^"]*)"?""" );
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        faxclass = to_string( "faxclass" );
    }

    public string query()
    {
        return "+FCLASS?";
    }

    public string test()
    {
        return "+FCLASS=?";
    }
}

public class PlusGCAP : SimpleAtCommand<string>
{
    public PlusGCAP()
    {
        base( "+GCAP", true );
    }
}

public void registerGenericAtCommands( HashMap<string,AtCommand> table )
{
    // register commands
    table[ "+CALA" ]             = new FsoGsm.PlusCALA();

    table[ "+CBC" ]              = new FsoGsm.PlusCBC();

    table[ "+CCLK" ]             = new FsoGsm.PlusCCLK();

    table[ "+CFUN" ]             = new FsoGsm.PlusCFUN();

    table[ "+CGCLASS" ]          = new FsoGsm.PlusCGCLASS();
    table[ "+CGMI" ]             = new FsoGsm.PlusCGMI();
    table[ "+CGMM" ]             = new FsoGsm.PlusCGMM();
    table[ "+CGMR" ]             = new FsoGsm.PlusCGMR();
    table[ "+CGSN" ]             = new FsoGsm.PlusCGSN();

    table[ "+CLVL" ]             = new FsoGsm.PlusCLVL();

    table[ "+CMICKEY" ]          = new FsoGsm.PlusCMICKEY();
    table[ "+CMUT" ]             = new FsoGsm.PlusCMUT();

    table[ "+CNMI" ]             = new FsoGsm.PlusCNMI();

    table[ "+COPS" ]             = new FsoGsm.PlusCOPS();

    table[ "+CPBR" ]             = new FsoGsm.PlusCPBR();
    table[ "+CPBS" ]             = new FsoGsm.PlusCPBS();
    table[ "+CPIN" ]             = new FsoGsm.PlusCPIN();

    table[ "+FCLASS" ]           = new FsoGsm.PlusFCLASS();

    table[ "+GCAP" ]             = new FsoGsm.PlusGCAP();
}

} /* namespace FsoGsm */
