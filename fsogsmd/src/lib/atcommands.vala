/**
 * Copyright (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

public class PlusCEER : AbstractAtCommand
{
    public int location;
    public int reason;
    public int ssrelease;

    public PlusCEER()
    {
        re = new Regex( """\+CEER: (?P<location>\d+),(?P<reason>\d+),(?P<ssrelease>\d+)""" );
        prefix = { "+CEER: " };
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        location = to_int( "location" );
        reason = to_int( "reason" );
        ssrelease = to_int( "ssrelease" );
    }

    public string execute()
    {
        return "+CEER";
    }
}

public class PlusCFUN : SimpleAtCommand<int>
{
    public PlusCFUN()
    {
        base( "+CFUN" );
    }
}

public class PlusCGACT : SimpleAtCommand<int>
{
    public PlusCGACT()
    {
        base( "+CGACT" );
    }
}

public class PlusCGATT : SimpleAtCommand<int>
{
    public PlusCGATT()
    {
        base( "+CGATT" );
    }
}

public class PlusCGCLASS : SimpleAtCommand<string>
{
    public PlusCGCLASS()
    {
        base( "+CGCLASS" );
    }
}

public class PlusCGDCONT : AbstractAtCommand
{
    public PlusCGDCONT()
    {
        prefix = { "+CGDCONT: " };
    }

    public string issue( string apn )
    {
        return @"+CGDCONT=1,\"IP\",\"$apn\"";
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

public class PlusCHLD : AbstractAtCommand
{
    public enum Action
    {
        DROP_ALL_OR_SEND_BUSY = 0,
        DROP_ALL_AND_ACCEPT_WAITING_OR_HELD = 1,
        DROP_SPECIFIC_AND_ACCEPT_WAITING_OR_HELD = 1,
        HOLD_ALL_AND_ACCEPT_WAITING_OR_HELD = 2,
        HOLD_SPECIFIC_AND_ACCEPT_WAITING_OR_HELD = 2,
        ACTIVATE_HELD = 3,
        DROP_SELF_AND_CONNECT_ACTIVE = 4
    }

    public string issue( Action action, int cid = 0 )
    {
        if ( cid > 0 )
        {
            return "+CHLD=%d%d".printf( (int)action, cid );
        }
        else
        {
            return "+CHLD=%d".printf( (int)action );
        }
    }
}

public class PlusCIMI : SimpleAtCommand<string>
{
    public PlusCIMI()
    {
        base( "+CIMI", true );
    }
}

public class PlusCLCC : AbstractAtCommand
{
    public FreeSmartphone.GSM.CallDetail[] calls;

    public PlusCLCC()
    {
        re = new Regex( """\+CLCC: (?P<id>\d),(?P<dir>\d),(?P<stat>\d),(?P<mode>\d),(?P<mpty>\d)(?:,"(?P<number>[\+0-9*#w]+)",(?P<typ>\d+)(?:,"(?P<name>[^"]*)")?)?""");
        prefix = { "+CLCC: " };
    }

    public override void parseMulti( string[] response ) throws AtCommandError
    {
        //FIXME: This should no longer be necessary; Vala now supports appending to public arrays as well
        var c = new FreeSmartphone.GSM.CallDetail[] {};
        foreach ( var line in response )
        {
            base.parse( line );
            var entry = FreeSmartphone.GSM.CallDetail(
                to_int( "id" ),
                Constants.instance().callStatusToEnum( to_int( "stat" ) ),
                new GLib.HashTable<string,Value?>( str_hash, str_equal )
            );

            var strvalue = GLib.Value( typeof(string) );
            strvalue = Constants.instance().callDirectionToString( to_int( "dir" ) );
            entry.properties.insert( "direction", strvalue );

            strvalue = Constants.instance().phonenumberTupleToString( to_string( "number" ), to_int( "typ" ) );
            entry.properties.insert( "peer", strvalue );

            strvalue = Constants.instance().callTypeToString( to_int( "mode" ) );
            entry.properties.insert( "type", strvalue );

            c += entry;
        }
        calls = c;
    }

    public string execute()
    {
        return "+CLCC";
    }
}

public class PlusCLCK : AbstractAtCommand
{
    public bool enabled;
    public int klass;

    public string facilities; // test

    public enum Mode
    {
        DISABLE = 0,
        ENABLE = 1,
        QUERY = 2,
    }

    public PlusCLCK()
    {
        re = new Regex( """\+CLCK: (?P<enabled>[01])(?:,(?P<class>\d+))?""" );
        tere = new Regex( """\+CLCK: \((?P<facilities>[^\)]*)\)""" );
        prefix = { "+CLCK: " };
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        enabled = to_int( "enabled" ) == 1;
        klass = to_int( "class" );
    }

    public override void parseTest( string response ) throws AtCommandError
    {
        base.parseTest( response );
        facilities = to_string( "facilities" );
    }

    public string query( string facility )
    {
        return "+CLCK=\"%s\",%d".printf( facility, (int)Mode.QUERY );
    }

    public string issue( string facility, bool enable, string pin )
    {
        return "+CLCK=\"%s\",%d,\"%s\"".printf( facility, enable ? (int)Mode.ENABLE : (int)Mode.DISABLE, pin );
    }

    public string test()
    {
        return "+CLCK=?";
    }
}

public class PlusCLVL : SimpleAtCommand<int>
{
    public PlusCLVL()
    {
        base( "+CLVL" );
    }
}

public class PlusCMGL : AbstractAtCommand
{
    public Gee.ArrayList<WrapSms> messagebook;

    public enum Mode
    {
        INVALID     = -1,
        REC_UNREAD  = 0,
        REC_READ    = 1,
        STO_UNSENT  = 2,
        STO_SENT    = 3,
        ALL         = 4,
    }

    public PlusCMGL()
    {
        re = new Regex( """\+CMGL: (?P<id>\d+),(?P<stat>\d),(?:"(?P<alpha>[0-9ABCDEF]*)")?,(?P<tpdulen>\d+)""");
        prefix = { "+CMGL: " };
    }

    public override void parseMulti( string[] response ) throws AtCommandError
    {
        messagebook = new Gee.ArrayList<WrapSms>();

        var tpdulen = 0;

        for ( int i = 0; i < response.length; ++i )
        {
            if ( i % 2 == 0 )
            {
                base.parse( response[i] );
                tpdulen = to_int( "tpdulen" );
            }
            else
            {
                var sms = Sms.Message.newFromHexPdu( response[i], tpdulen );
                if ( sms != null )
                {
                    messagebook.add( new WrapSms( (owned) sms) );
                }
            }
        }
    }

    public string issue( Mode mode )
    {
        assert( mode != Mode.INVALID );
        return "+CMGL=%d".printf( (int)mode );
    }
}

public class PlusCMGR : AbstractAtCommand
{
    public string hexpdu;
    public int tpdulen;

    public PlusCMGR()
    {
        re = new Regex( """\+CMGR: (?P<stat>\d),(?:"(?P<alpha>[0-9ABCDEF]*)")?,(?P<tpdulen>\d+)""");
        prefix = { "+CMGR: " };
        length = 2;
    }

    public override void parseMulti( string[] response ) throws AtCommandError
    {
        base.parse( response[0] );
        tpdulen = to_int( "tpdulen" );
        hexpdu = response[1];
    }

    public string issue( uint index )
    {
        return @"+CMGR=$index";
    }
}

public class PlusCMGS : AbstractAtCommand
{
    public PlusCMGS()
    {
        re = new Regex( """\+CMGS: (?P<id>\d)(?:,"(?P<name>[0-9ABCDEF]*)")?""" );
        prefix = { "+CMGS: " };
    }

    public string issue( WrapHexPdu pdu )
    {
        return "AT+CMGS=%u\r\n%s%c".printf( pdu.tpdulen, pdu.hexpdu, '\x1A' );
    }

    public override string get_prefix() { return ""; }
    public override string get_postfix() { return ""; }
}

public class PlusCMGW : AbstractAtCommand
{
    public PlusCMGW()
    {
        re = new Regex( """\+CMGW: (?P<id>\d+)""" );
        prefix = { "+CMGW: " };
    }

    /*
    public string issue( ShortMessage.HexPdu hexpdu )
    {
        return "AT+CMGW=%d\r\n%s%c".printf( hexpdu.tpdulen, hexpdu.pdu, '\x1A' );
    }
    */

    public override string get_prefix() { return ""; }
    public override string get_postfix() { return ""; }
}

public class PlusCMICKEY : SimpleAtCommand<int>
{
    public PlusCMICKEY()
    {
        base( "+CMICKEY" );
    }
}

public class PlusCMTI : AbstractAtCommand
{
    public string storage;
    public int index;

    public PlusCMTI()
    {
        re = new Regex( """\+CMTI: "(?P<storage>[^"]*)",(?P<id>\d+)""" );
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        storage = to_string( "storage" );
        index = to_int( "id" );
    }
    // unsolicited only, not a command
}

public class PlusCMMS : SimpleAtCommand<int>
{
    public PlusCMMS()
    {
        base( "+CMMS" );
    }
}

public class PlusCMUT : SimpleAtCommand<int>
{
    public PlusCMUT()
    {
        base( "+CMUT" );
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

public class PlusCOPS : AbstractAtCommand
{
    public int format;
    public int mode;
    public string oper;
    public string act;
    public int status;

    public FreeSmartphone.GSM.NetworkProvider[] providers;

    public enum Action
    {
        REGISTER_WITH_BEST_PROVIDER     = 0,
        REGISTER_WITH_SPECIFIC_PROVIDER = 1,
        UNREGISTER                      = 2,
        SET_FORMAT                      = 3,
    }

    public enum Format
    {
        ALPHANUMERIC                    = 0,
        NUMERIC                         = 2,
    }

    public PlusCOPS()
    {
        re = new Regex( """\+COPS:\ (?P<mode>\d)(,(?P<format>\d)?(,"(?P<oper>[^"]*)")?)?(?:,(?P<act>\d))?""" );
        tere = new Regex( """\((?P<status>\d),(?:"(?P<longname>[^"]*)")?,(?:"(?P<shortname>[^"]*)")?,"(?P<mccmnc>[^"]*)"(?:,(?P<act>\d))?\)""" );
        prefix = { "+COPS: " };
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        mode = to_int( "mode" );
        format = to_int( "format" );
        oper = to_string( "oper" );
        act = Constants.instance().networkProviderActToString( to_int( "act" ) );
    }

    public override void parseTest( string response ) throws AtCommandError
    {
        base.parseTest( response );
        var providers = new FreeSmartphone.GSM.NetworkProvider[] {};
        do
        {
            var p = FreeSmartphone.GSM.NetworkProvider(
                Constants.instance().networkProviderStatusToString( to_int( "status" ) ),
                to_string( "longname" ),
                to_string( "shortname" ),
                to_string( "mccmnc" ),
                Constants.instance().networkProviderActToString( to_int( "act" ) ) );
            providers += p;
        }
        while ( mi.next() );
        this.providers = providers;
    }

    public string issue( Action action, Format format = Format.ALPHANUMERIC, int param = 0 )
    {
        if ( action == Action.REGISTER_WITH_BEST_PROVIDER )
        {
            return "+COPS=0,0";
        }
        else
        {
            return "+COPS=%d,%d,\"%d\"".printf( (int)action, (int)format, (int)param );
        }
    }

    public string query( Format format = Format.ALPHANUMERIC )
    {
        return "+COPS=%d,%d;+COPS?".printf( (int)Action.SET_FORMAT, (int)format );
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
        re = new Regex( """\+CPBR: (?P<id>\d+),"(?P<number>[\+0-9*#w]*)",(?P<typ>\d+)(?:,"(?P<name>[^"]*)")?""" );
        tere = new Regex( """\+CPBR: \((?P<min>\d+)-(?P<max>\d+)\),\d+,\d+""" );
        prefix = { "+CPBR: " };
    }

    public override void parseMulti( string[] response ) throws AtCommandError
    {
        var phonebook = new FreeSmartphone.GSM.SIMEntry[] {};
        foreach ( var line in response )
        {
            base.parse( line );
            var entry = FreeSmartphone.GSM.SIMEntry( to_int( "id" ), to_string( "number" ), decodeString( to_string( "name" ) ) );
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
    public FreeSmartphone.GSM.SIMAuthStatus status;

    public PlusCPIN()
    {
        re = new Regex( """\+CPIN:\ "?(?P<status>[^"]*)"?""" );
        prefix = { "+CPIN: " };
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        status = Constants.instance().simAuthStatusToEnum( to_string( "status" ) );
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

public class PlusCPWD : AbstractAtCommand
{
    public PlusCPWD()
    {
        re = new Regex( """\+CPWD:\ "?(?P<pin>[^"]*)"?""" );
        prefix = { "+CPWD: " };
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
    }

    public string issue( string facility, string p1, string p2 )
    {
        return @"+CPWD=\"$facility\",\"$p1\",\"$p2\"";
    }

    public string query()
    {
        return "+CPWD?";
    }
}

public class PlusCREG : AbstractAtCommand
{
    public int mode;
    public int status;
    public string lac;
    public string cid;

    public PlusCREG()
    {
        re = new Regex( """\+CREG: (?P<mode>\d),(?P<status>\d)(?:,"?(?P<lac>[0-9A-F]*)"?,"?(?P<cid>[0-9A-F]*)"?)?""" );
        prefix = { "+CREG: " };
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        mode = to_int( "mode" );
        status = to_int( "status" );
        lac = to_string( "lac" );
        cid = to_string( "cid" );
    }

    public string query()
    {
        return "+CREG?";
    }

    public string issue( int mode )
    {
        return "+CREG=%d";
    }

    public string queryFull( int restoreMode )
    {
        return @"+CREG=2;+CREG?;+CREG=$restoreMode";
    }
}

public class PlusCRSM : AbstractAtCommand
{
    public string payload;

    public PlusCRSM()
    {
        re = new Regex( """\+CRSM: 144,0,"?(?P<payload>[0-9A-Z]+)"?""" );
        prefix = { "+CRSM: " };
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        payload = to_string( "payload" );
    }

    public string issue( int command, int p1, int p2, int offset, int length )
    {
        return @"+CRSM=$command,$p1,$p2,$offset,$length";
    }
}

public class PlusCSCA : AbstractAtCommand
{
    public string number;

    public PlusCSCA()
    {
        re = new Regex( """\+CSCA: "(?P<number>%s*)",(?P<ntype>\d+)""".printf( Constants.PHONE_DIGITS_RE ) );
        prefix = { "+CSCA: " };
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        number = Constants.instance().phonenumberTupleToString( to_string( "number" ), to_int( "ntype" ) );
    }

    public string query()
    {
        return "+CSCA?";
    }

    public string issue( string number )
    {
        return "+CSCA=" + Constants.instance().phonenumberStringToTuple( number );
    }
}

public class PlusCSCS : SimpleAtCommand<string>
{
    public PlusCSCS()
    {
        base( "+CSCS" );
    }
}

public class PlusCSQ : AbstractAtCommand
{
    public int signal;

    public PlusCSQ()
    {
        re = new Regex( """\+CSQ: (?P<signal>\d+),(?P<ber>\d+)""" );
        prefix = { "+CSQ: " };
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        signal = Constants.instance().networkSignalToPercentage( to_int( "signal" ) );
    }

    public string execute()
    {
        return "+CSQ";
    }
}

public class PlusFCLASS : SimpleAtCommand<string>
{
    public PlusFCLASS()
    {
        base( "+FCLASS", true );
    }
}

public class PlusGCAP : SimpleAtCommand<string>
{
    public PlusGCAP()
    {
        base( "+GCAP", true );
    }
}

public class PlusVTS : AbstractAtCommand
{
    public const string DTMF_VALID_CHARS = "0123456789ABC+#";

    public string issue( string tones )
    {
        /*
        var tone = "";
        for ( int i = 0; i < tone.length; ++i )
        {
            var c = tones[i];
            if ( c in DTMF_VALID_CHARS )
            {
                tone += c;
            }
        }
        */
        return @"+VTS=$tones";
    }
}

public class V250A : V250terCommand
{
    public V250A()
    {
        base( "A" );
    }
}

public class V250D : V250terCommand
{
    public V250D()
    {
        base( "D" );
    }

    public string issue( string number, bool voice = true )
    {
        var postfix = voice ? ";" : "";
        return @"D$number$postfix";
    }
}

public class V250H : V250terCommand
{
    public V250H()
    {
        base( "H" );
    }
}

public void registerGenericAtCommands( HashMap<string,AtCommand> table )
{
    // low level access (SIM, charset, etc.)
    table[ "+CRSM" ]             = new FsoGsm.PlusCRSM();
    table[ "+CSCS" ]             = new FsoGsm.PlusCSCS();

    // informational
    table[ "+CGCLASS" ]          = new FsoGsm.PlusCGCLASS();
    table[ "+CGMI" ]             = new FsoGsm.PlusCGMI();
    table[ "+CGMM" ]             = new FsoGsm.PlusCGMM();
    table[ "+CGMR" ]             = new FsoGsm.PlusCGMR();
    table[ "+CGSN" ]             = new FsoGsm.PlusCGSN();
    table[ "+CIMI" ]             = new FsoGsm.PlusCIMI();
    table[ "+FCLASS" ]           = new FsoGsm.PlusFCLASS();
    table[ "+GCAP" ]             = new FsoGsm.PlusGCAP();

    // access control
    table[ "+CLCK" ]             = new FsoGsm.PlusCLCK();
    table[ "+CPIN" ]             = new FsoGsm.PlusCPIN();
    table[ "+CPWD" ]             = new FsoGsm.PlusCPWD();

    // URC
    table[ "+CNMI" ]             = new FsoGsm.PlusCNMI();

    // device and peripheral control
    table[ "+CBC" ]              = new FsoGsm.PlusCBC();
    table[ "+CFUN" ]             = new FsoGsm.PlusCFUN();
    table[ "+CLVL" ]             = new FsoGsm.PlusCLVL();
    table[ "+CMUT" ]             = new FsoGsm.PlusCMUT();

    // time and date related
    table[ "+CALA" ]             = new FsoGsm.PlusCALA();
    table[ "+CCLK" ]             = new FsoGsm.PlusCCLK();

    // network
    table[ "+COPS" ]             = new FsoGsm.PlusCOPS();
    table[ "+CREG" ]             = new FsoGsm.PlusCREG();
    table[ "+CSQ" ]              = new FsoGsm.PlusCSQ();

    // call control
    table[ "A" ]                 = new FsoGsm.V250A();
    table[ "H" ]                 = new FsoGsm.V250H();
    table[ "D" ]                 = new FsoGsm.V250D();
    table[ "+CEER" ]             = new FsoGsm.PlusCEER();
    table[ "+CHLD" ]             = new FsoGsm.PlusCHLD();
    table[ "+CLCC" ]             = new FsoGsm.PlusCLCC();
    table[ "+VTS" ]              = new FsoGsm.PlusVTS();

    // phonebook
    table[ "+CPBR" ]             = new FsoGsm.PlusCPBR();
    table[ "+CPBS" ]             = new FsoGsm.PlusCPBS();

    // sms
    table[ "+CMGL" ]             = new FsoGsm.PlusCMGL();
    table[ "+CMGR" ]             = new FsoGsm.PlusCMGR();
    table[ "+CMGS" ]             = new FsoGsm.PlusCMGS();
    table[ "+CMMS" ]             = new FsoGsm.PlusCMMS();
    table[ "+CMTI" ]             = new FsoGsm.PlusCMTI();
    table[ "+CSCA" ]             = new FsoGsm.PlusCSCA();

    // pdp
    table[ "+CGACT" ]            = new FsoGsm.PlusCGACT();
    table[ "+CGATT" ]            = new FsoGsm.PlusCGATT();
    table[ "+CGDCONT" ]          = new FsoGsm.PlusCGDCONT();

    // misc
    table[ "+CMICKEY" ]          = new FsoGsm.PlusCMICKEY();
    table[ "CUSTOM" ]            = new FsoGsm.CustomAtCommand();
}

} /* namespace FsoGsm */
