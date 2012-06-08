/*
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

/**
 * This file contains AT command specifications defined the official 3GPP GSM
 * specifications, such as 05.05 and 07.07.
 *
 * Do _not_ add vendor-specific commands here, instead add them to your modem plugin.
 **/

using Gee;
using FsoGsm.Constants;

namespace FsoGsm {

internal const uint MODEM_COMM_TIMEOUT = 5;
internal const uint SIM_COMM_TIMEOUT = 20;
internal const uint NETWORK_COMM_TIMEOUT = 120;
internal const uint VOICE_COMM_TIMEOUT = 3600 * 24;

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
        try
        {
            re = new Regex( str );
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail here if Regex is broken
        }
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
    public enum Status
    {
        DISCHARGING = 0,
        CHARGING = 1,
        AC = 2,
        UNKNOWN = 3
    }

    public Status status;
    public int level;

    public PlusCBC()
    {
        try
        {
            re = new Regex( """\+CBC: (?P<status>[0123]),(?P<level>\d+)""" );
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail here if Regex is broken
        }
        prefix = { "+CBC: " };
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        status = (Status) to_int( "status" );
        level = to_int( "level" );
    }

    public string execute()
    {
        return "+CBC";
    }
}

public class PlusCBM : AbstractAtCommand
{
    public string hexpdu;
    public int tpdulen;

    public PlusCBM()
    {
        try
        {
            re = new Regex( """\+CBM: (?P<tpdulen>\d+)""");
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail here if Regex is broken
        }
        prefix = { "+CBM: " };
        length = 2;
    }

    public override void parseMulti( string[] response ) throws AtCommandError
    {
        base.parse( response[0] );
        tpdulen = to_int( "tpdulen" );
        hexpdu = response[1];
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
        try
        {
            // some modems strip the leading zero for one-digit chars
            re = new Regex( """\+CCLK: "?(?P<year>\d?\d)/(?P<month>\d?\d)/(?P<day>\d?\d),(?P<hour>\d?\d):(?P<minute>\d?\d):(?P<second>\d?\d)(?:[\+-](?P<tzoffset>\d\d))?"?""" );
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail here if Regex is broken
        }
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

public class PlusCDS : AbstractAtCommand
{
    public string hexpdu;
    public int tpdulen;

    public PlusCDS()
    {
        try
        {
            re = new Regex( """\+CDS: (?P<tpdulen>\d+)""");
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail here if Regex is broken
        }
        prefix = { "+CDS: " };
        length = 2;
    }

    public override void parseMulti( string[] response ) throws AtCommandError
    {
        base.parse( response[0] );
        tpdulen = to_int( "tpdulen" );
        hexpdu = response[1];
    }
}

public class PlusCEER : AbstractAtCommand
{
    public string reason;

    public PlusCEER()
    {
        try
        {
            re = new Regex( """\+CEER: (?:(?P<v0>\d+),)?(?P<v1>\d+),(?P<v2>\d+),(?P<v3>\d+)""" );
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail here if Regex is broken
        }
        prefix = { "+CEER: " };
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        var v0 = to_int( "v0" );
        var v1 = to_int( "v1" );
        var v2 = to_int( "v2" );
        var v3 = to_int( "v3" );

        if ( v0 == 0 && v1 == 0 && v2 != 0 && v3 != 0 )
        {
            reason = Constants.ceerCauseToString( v1, v2, v3 );
        }
        else
        {
            reason = Constants.ceerCauseToString( v0, v1, v3 );
        }
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

    public override uint get_timeout() { return SIM_COMM_TIMEOUT; }
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

public class PlusCGREG : AbstractAtCommand
{
    public int mode;
    public int status;
    public string lac;
    public string cid;

    public PlusCGREG()
    {
        try
        {
            re = new Regex( """\+CGREG: (?P<mode>\d),(?P<status>\d)(?:,"?(?P<lac>[0-9A-F]*)"?,"?(?P<cid>[0-9A-F]*)"?)?""" );
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail here if Regex is broken
        }
        prefix = { "+CGREG: " };
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
        return "+CGREG?";
    }

    public string issue( int mode )
    {
        return @"+CGREG=$mode";
    }

    public string queryFull( int restoreMode )
    {
        return @"+CGREG=2;+CGREG?;+CGREG=$restoreMode";
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

public class PlusCIEV : TwoParamsAtCommand<int,int>
{
    public PlusCIEV()
    {
        base( "+CIEV" );
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
        try
        {
            re = new Regex( """\+CLCC: (?P<id>\d),(?P<dir>\d),(?P<stat>\d),(?P<mode>\d),(?P<mpty>\d)(?:,"(?P<number>[\+0-9*#w]+)",(?P<typ>\d+)(?:,"(?P<name>[^"]*)")?)?""");
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail here if Regex is broken
        }
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
                Constants.callStatusToEnum( to_int( "stat" ) ),
                new GLib.HashTable<string,Variant>( str_hash, str_equal )
            );

            Variant strvalue;
            strvalue = Constants.callDirectionToString( to_int( "dir" ) );
            entry.properties.insert( "direction", strvalue );

            strvalue = Constants.phonenumberTupleToString( to_string( "number" ), to_int( "typ" ) );
            entry.properties.insert( "peer", strvalue );

            strvalue = Constants.callTypeToString( to_int( "mode" ) );
            entry.properties.insert( "type", strvalue );

            c += entry;
        }
        calls = c;
    }

    public string execute()
    {
        return "+CLCC";
    }

    public string query()
    {
        return "+CLCC?";
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
        try
        {
            re = new Regex( """\+CLCK: (?P<enabled>[01])(?:,(?P<class>\d+))?""" );
            tere = new Regex( """\+CLCK: \((?P<facilities>[^\)]*)\)""" );
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail here if Regex is broken
        }
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

public class PlusCLIR : SimpleAtCommand<int>
{
    public PlusCLIR()
    {
        base( "+CLIR" );
    }
}

public class PlusCLVL : SimpleAtCommand<int>
{
    public PlusCLVL()
    {
        base( "+CLVL" );
    }
}

public class PlusCMGD : SimpleAtCommand<int>
{
    public PlusCMGD()
    {
        base( "+CMGD" );
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
        try
        {
            re = new Regex( """\+CMGL: (?P<id>\d+),(?P<stat>\d),(?:"(?P<alpha>[0-9ABCDEF]*)")?,(?P<tpdulen>\d+)""");
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail here if Regex is broken
        }
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
                    messagebook.add( new WrapSms( (owned) sms, to_int( "id" ) ) );
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
    public PlusCMGL.Mode status;
    public string hexpdu;
    public int tpdulen;

    public PlusCMGR()
    {
        try
        {
            re = new Regex( """\+CMGR: (?P<stat>\d),(?:"(?P<alpha>[0-9ABCDEF]*)")?,(?P<tpdulen>\d+)""");
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail here if Regex is broken
        }
        prefix = { "+CMGR: " };
        length = 2;
    }

    public override void parseMulti( string[] response ) throws AtCommandError
    {
        base.parse( response[0] );
        status = (PlusCMGL.Mode) to_int( "stat" );
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
    public int refnum;

    public PlusCMGS()
    {
        try
        {
            re = new Regex( """\+CMGS: (?P<id>\d+)(?:,"(?P<name>[0-9ABCDEF]*)")?""" );
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail here if Regex is broken
        }
        prefix = { "+CMGS: " };
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        refnum = to_int( "id" );
    }

    public string issue( WrapHexPdu pdu )
    {
        return "AT+CMGS=%u\r\n%s%c".printf( pdu.tpdulen, pdu.hexpdu, '\x1A' );
    }

    public override string get_prefix() { return ""; }
    public override string get_postfix() { return ""; }

    public override uint get_timeout() { return NETWORK_COMM_TIMEOUT; }
}

public class PlusCMGW : AbstractAtCommand
{
    public int memory_index;

    public PlusCMGW()
    {
        try
        {
            re = new Regex( """\+CMGW: (?P<id>\d+)""" );
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail here if Regex is broken
        }
        prefix = { "+CMGW: " };
    }

    public string issue( WrapHexPdu pdu )
    {
        return "AT+CMGW=%u\r\n%s%c".printf( pdu.tpdulen, pdu.hexpdu, '\x1A' );
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        memory_index = to_int( "id" );
    }

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

public class PlusCMSS : AbstractAtCommand
{
    public int refnum;

    public PlusCMSS()
    {
        try
        {
            re = new Regex( """\+CMSS: (?P<id>\d)(?:,"(?P<name>[0-9ABCDEF]*)")?""" );
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail here if Regex is broken
        }
        prefix = { "+CMSS: " };
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        refnum = to_int( "id" );
    }

    public string issue( int index )
    {
        return @"+CMSS=$index";
    }
}

public class PlusCMT : AbstractAtCommand
{
    public string hexpdu;
    public int tpdulen;

    public PlusCMT()
    {
        try
        {
            re = new Regex( """\+CMT: (?:"[0-9A-F]*")?,?(?P<tpdulen>\d+)""");
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail here if Regex is broken
        }
        prefix = { "+CMT: " };
        length = 2;
    }

    public override void parseMulti( string[] response ) throws AtCommandError
    {
        base.parse( response[0] );
        tpdulen = to_int( "tpdulen" );
        hexpdu = response[1];
    }
}

public class PlusCMTI : AbstractAtCommand
{
    public string storage;
    public int index;

    public PlusCMTI()
    {
        try
        {
            re = new Regex( """\+CMTI: "(?P<storage>[^"]*)",(?P<id>\d+)""" );
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail here if Regex is broken
        }

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

public class PlusCNMA : SimpleAtCommand<int>
{
    public PlusCNMA()
    {
        base( "+CNMA" );
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
        try
        {
            re = new Regex( """\+CNMI: (?P<mode>\d),(?P<mt>\d),(?P<bm>\d),(?P<ds>\d),(?P<bfr>\d)""" );
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail here if Regex is broken
        }
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

public class PlusCOPN : AbstractAtCommand
{
    public GLib.HashTable<string,string> operators;

    public PlusCOPN()
    {
        try
        {
            re = new Regex( """\+COPN: "(?P<mccmnc>[^"]*)","(?P<name>[^"]*)"""" );
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail here if Regex is broken
        }
        prefix = { "+COPN: " };
    }

    public override void parseMulti( string[] response ) throws AtCommandError
    {
        operators = new GLib.HashTable<string,string>( GLib.str_hash, GLib.str_equal );
        foreach ( var line in response )
        {
            base.parse( line );
            var mccmnc = to_string( "mccmnc" );
            var name = decodeString( to_string( "name" ) );
            message( @"adding operator $mccmnc = $name" );
            operators.insert( to_string( "mccmnc" ), to_string( "name" ) );
        }
    }

    public string execute()
    {
        return "+COPN";
    }

    public override uint get_timeout() { return SIM_COMM_TIMEOUT; }
}

public class PlusCOPS : AbstractAtCommand
{
    public static bool providerNameDeliveredInConfiguredCharset;

    public int format;
    public int mode;
    public string oper;
    public string act;

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
        ALPHANUMERIC_SHORT              = 1,
        NUMERIC                         = 2,
    }

    public PlusCOPS()
    {
        try
        {
            re = new Regex( """\+COPS:\ (?P<mode>\d)(,(?P<format>\d)?(,"(?P<oper>[^"]*)")?)?(?:,(?P<act>\d))?""" );
            tere = new Regex( """\((?P<status>\d),(?:"(?P<longname>[^"]*)")?,(?:"(?P<shortname>[^"]*)")?,"(?P<mccmnc>[^"]*)"(?:,(?P<act>\d))?\)""" );
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail here if Regex is broken
        }
        prefix = { "+COPS: " };
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        mode = to_int( "mode" );
        format = to_int( "format" );
        oper = to_string( "oper" );
        if ( format != Format.NUMERIC && PlusCOPS.providerNameDeliveredInConfiguredCharset )
        {
            oper = decodeString( oper );
        }
        act = Constants.networkProviderActToString( to_int( "act" ) );
    }

    public override void parseTest( string response ) throws AtCommandError
    {
        base.parseTest( response );
        var providers = new FreeSmartphone.GSM.NetworkProvider[] {};
        try
        {
            do
            {
                var p = FreeSmartphone.GSM.NetworkProvider(
                    Constants.networkProviderStatusToString( to_int( "status" ) ),
                    to_string( "shortname" ),
                    to_string( "longname" ),
                    to_string( "mccmnc" ),
                    Constants.networkProviderActToString( to_int( "act" ) ) );
                providers += p;
            }
            while ( mi.next() );
        }
        catch ( GLib.RegexError e )
        {
            FsoFramework.theLogger.error( @"Regex error: $(e.message)" );
            throw new AtCommandError.UNABLE_TO_PARSE( e.message );
        }
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

    public override uint get_timeout() { return NETWORK_COMM_TIMEOUT; }
}

public class PlusCPBR : AbstractAtCommand
{
    public int min;
    public int max;

    public FreeSmartphone.GSM.SIMEntry[] phonebook;

    public PlusCPBR()
    {
        try
        {
            re = new Regex( """\+CPBR: (?P<id>\d+),"(?P<number>[\+0-9*#w]*)",(?P<typ>\d+)(?:,"(?P<name>[^"]*)")?""" );
            tere = new Regex( """\+CPBR: \((?P<min>\d+)-(?P<max>\d+)\),\d+,\d+""" );
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail here if Regex is broken
        }
        prefix = { "+CPBR: " };
    }

    public override void parseMulti( string[] response ) throws AtCommandError
    {
        var phonebook = new FreeSmartphone.GSM.SIMEntry[] {};
        foreach ( var line in response )
        {
            base.parse( line );
            var number = Constants.phonenumberTupleToString( to_string( "number" ), to_int( "typ" ) );
            var entry = FreeSmartphone.GSM.SIMEntry( to_int( "id" ), decodeString( to_string( "name" ) ), number );
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
        try
        {
            tere = new Regex( """\"(?P<book>[A-Z][A-Z])\"""" );
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail here if Regex is broken
        }
        prefix = { "+CPBS: " };
    }

    public override void parseTest( string response ) throws AtCommandError
    {
        base.parseTest( response );
        var books = new string[] {};
        try
        {
            do
            {
                books += /* Constants.simPhonebookNameToString( */ to_string( "book" ) /* ) */;
            }
            while ( mi.next() );
        }
        catch ( GLib.RegexError e )
        {
            FsoFramework.theLogger.error( @"Regex error: $(e.message)" );
            throw new AtCommandError.UNABLE_TO_PARSE( e.message );
        }
        phonebooks = books;
    }

    public string test()
    {
        return "+CPBS=?";
    }
}

public class PlusCPBW : AbstractAtCommand
{
    public int max;
    public int nlength;
    public int tlength;

    public PlusCPBW()
    {
        try
        {
            tere = new Regex( """\+CPBW: \((?P<min>\d+)-(?P<max>\d+)\),(?P<nlength>\d*),\((?P<mintype>\d+)-(?P<maxtype>\d+)\),(?P<tlength>\d*)""" );
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail here if Regex is broken
        }
        prefix = { "+CPBW: " };
    }

    public override void parseTest( string response ) throws AtCommandError
    {
        base.parseTest( response );
        max = to_int( "max" );
        nlength = to_int( "nlength" );
        tlength = to_int( "tlength" );
    }

    public string issue( string cat, int location, string number = "", string name = "" )
    {
        var cmd = @"+CPBS=\"$cat\";+CPBW=$location";
        if ( number != "" )
        {
            cmd += ",%s,\"%s\"".printf( Constants.phonenumberStringToTuple( number ), encodeString( name ) );
        }
        return cmd;
    }

    public string test( string cat )
    {
        return @"+CPBS=\"$cat\";+CPBW=?";
    }
}

public class PlusCPIN : AbstractAtCommand
{
    public FreeSmartphone.GSM.SIMAuthStatus status;

    public PlusCPIN()
    {
        try
        {
            re = new Regex( """\+CPIN:\ "?(?P<status>[^"]*)"?""" );
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail here if Regex is broken
        }
        prefix = { "+CPIN: " };
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        status = Constants.simAuthStatusToEnum( to_string( "status" ) );
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

    public override uint get_timeout() { return SIM_COMM_TIMEOUT; }
}

public class PlusCPMS : AbstractAtCommand
{
    public int used;
    public int total;

    public PlusCPMS()
    {
        try
        {
            re = new Regex( """\+CPMS: "(?P<s1>[^"]*)",(?P<s1u>\d*),(?P<s1t>\d*),"(?P<s2>[^"]*)",(?P<s2u>\d*),(?P<s2t>\d*),"(?P<s3>[^"]*)",(?P<s3u>\d*),(?P<s3t>\d*)""" );
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail here if Regex is broken
        }
        prefix = { "+CPMS: " };
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        used = to_int( "s1u" );
        total = to_int( "s1t" );
    }

    public string query()
    {
        return "+CPMS?";
    }

    public string issue( string s1 = "SM", string s2 = "SM", string s3 = "SM" )
    {
        return @"+CPMS=\"$s1\",\"$s2\",\"$s3\"";
    }
}

public class PlusCPWD : AbstractAtCommand
{
    public PlusCPWD()
    {
        try
        {
            re = new Regex( """\+CPWD:\ "?(?P<pin>[^"]*)"?""" );
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail here if Regex is broken
        }
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

    public enum Mode
    {
        DISABLE = 0,
        ENABLE_WITH_NETORK_REGISTRATION = 1,
        ENABLE_WITH_NETORK_REGISTRATION_AND_LOCATION = 2,
    }

    public PlusCREG()
    {
        try
        {
            re = new Regex( """\+CREG: (?P<mode>\d),(?P<status>\d)(?:,"?(?P<lac>[0-9A-F]*)"?,"?(?P<cid>[0-9A-F]*)"?)?""" );
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail here if Regex is broken
        }
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

    public string issue( Mode mode )
    {
        return "+CREG=%i".printf( (int) mode );
    }
}

public class PlusCRSM : AbstractAtCommand
{
    public string payload;

    public PlusCRSM()
    {
        try
        {
            re = new Regex( """\+CRSM: 144,0,"?(?P<payload>[0-9A-Z]+)"?""" );
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail here if Regex is broken
        }
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
        try
        {
            re = new Regex( """\+CSCA: "(?P<number>%s*)",(?P<ntype>\d+)""".printf( Constants.PHONE_DIGITS_RE ) );
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail here if Regex is broken
        }
        prefix = { "+CSCA: " };
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        number = Constants.phonenumberTupleToString( to_string( "number" ), to_int( "ntype" ) );
    }

    public string query()
    {
        return "+CSCA?";
    }

    public string issue( string number )
    {
        return "+CSCA=" + Constants.phonenumberStringToTuple( number );
    }
}

public class PlusCSCB : AbstractAtCommand
{
    public int mode;
    public int channels;
    public int encodings;

    public enum Mode
    {
        NONE,
        ALL
    }

    public PlusCSCB()
    {
        try
        {
            re = new Regex( """\+CSCB: +(?P<mode>[01]), *"(?P<channels>\d*)", *"(?P<encodings>\d*)"""" );
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail here if Regex is broken
        }
        prefix = { "+CSCB: " };
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        mode = to_int( "mode" );
        channels = to_int( "channels" );
        encodings = to_int( "encodings" );
    }

    public string query()
    {
        return "+CSCB?";
    }

    public string issue( Mode m )
    {
        return "+CSCB=%u,\"\",\"\"".printf( m == Mode.NONE ? 0 : 1 );
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
        try
        {
            re = new Regex( """\+CSQ: (?P<signal>\d+),(?P<ber>\d+)""" );
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail here if Regex is broken
        }
        prefix = { "+CSQ: " };
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        signal = Constants.networkSignalToPercentage( to_int( "signal" ) );
    }

    public string execute()
    {
        return "+CSQ";
    }
}

public class PlusCSSI : SimpleAtCommand<int>
{
    public PlusCSSI()
    {
        base( "+CSSI" );
    }
}

public class PlusCSSU : SimpleAtCommand<int>
{
    public PlusCSSU()
    {
        base( "+CSSU" );
    }
}

public class PlusCUSD : AbstractAtCommand
{
    public enum Mode
    {
        COMPLETED = 0,
        USERACTION = 1,
        TERMINATED = 2,
        LOCALCLIENT = 3,
        UNSUPPORTED = 4,
        TIMEOUT = 5,
    }

    public Mode mode;
    public string result;
    public int code;

    public PlusCUSD()
    {
        try
        {
            re = new Regex( """\+CUSD: (?P<mode>\d)(?:,"(?P<result>[a-zA-Z0-9]*)"(?:,(?P<code>\d+))?)?""" );
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail here if Regex is broken
        }
        prefix = { "+CUSD: " };
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        mode = (Mode)to_int( "mode" );
        result = decodeString( to_string( "result" ) );
        code = to_int( "code" );
    }

    public string query( string request )
    {
        return "+CUSD=1,\"%s\",15".printf( encodeString( request ) );
    }

    public string issue( bool enable )
    {
        return "+CUSD=%u".printf( enable ? 1 : 0 );
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
    public string issue( string tones )
    {
        var command = @"+VTS=$(tones[0])";
        for ( var n = 1; n < tones.length; n++ )
            command += @";+VTS=$(tones[n])";
        return command;
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
        var safenumber = Constants.cleanPhoneNumber( number );
        return @"D$safenumber$postfix";
    }

    public override uint get_timeout() { return VOICE_COMM_TIMEOUT; }
}

public class V250H : V250terCommand
{
    public V250H()
    {
        base( "H" );
    }
}

public class PlusCCFC : AbstractAtCommand
{
    public bool active { get; private set; }
    public BearerClass class1 { get; private set; }
    public string number { get; private set; }
    public int number_type { get; private set; }
    public string subaddr { get; private set; }
    public int satype { get; private set; }
    public int timeout { get; private set; }

    public PlusCCFC()
    {
        try
        {
            // +CCFC: <status>,<class1>[,<number>,<type>[,<subaddr>,<satype>[,<time>]]]
            re = new Regex( """\+CCFC: (?P<status>[01]),(?P<class1>\d)(?:,"(?P<number>[\+0-9*#w]+)",(?P<type>\d+)(?:,"(?P<subaddr>[\+0-9*#w]+)",(?P<satype>\d+)(?:,(?P<time>\d+))?)?)?""");
        }
        catch ( GLib.RegexError e )
        {
            stdout.printf(@"error: $(e.message)\n");
            assert_not_reached(); // fail here if Regex is broken
        }

        prefix = { "+CCFC: " };
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        active = ( to_int( "status" ) == 1 );
        class1 = (BearerClass) to_int( "class1" );
        number = to_string( "number" );
        number_type = to_int( "type" );
        subaddr = to_string( "subaddr" );
        satype = to_int( "satype" );
        timeout = to_int( "time" );
    }

    public string query( CallForwardingType type, BearerClass cls = FsoGsm.Constants.BearerClass.DEFAULT )
    {
        if ( cls == BearerClass.DEFAULT )
            return "+CCFC=%d,2".printf( (int) type );
        return "+CCFC=%d,2,,,%d".printf( (int) type, (int) cls );
    }

    public string issue( CallForwardingMode mode,
        CallForwardingType type, BearerClass cls = FsoGsm.Constants.BearerClass.DEFAULT )
    {
        var command = @"+CCFC=%d,%d".printf( (int) type, (int) mode );
        if ( cls != BearerClass.DEFAULT )
            command += ",,,%d".printf( (int) cls );
        return command;
    }

    public string issue_ext( CallForwardingMode mode, CallForwardingType type,
        BearerClass cls, string number, int time)
    {
        int number_type = determinePhoneNumberType( number );
        var command = "+CCFC=%d,%d,\"%s\",%d,%d".printf( (int) type,
            (int) mode, number, number_type, (int) cls );

        if ( type == CallForwardingType.NO_REPLY ||
             type == CallForwardingType.ALL ||
             type == CallForwardingType.ALL_CONDITIONAL )
        {
            command += ",,,%d".printf( time );
        }

        return command;
    }
}

public class PlusCTFR : AbstractAtCommand
{
    public string issue( string number, int number_type = 0 )
    {
        if ( number_type == 0 )
            return @"+CTFR=$number";
        return @"+CTFR=$number,$number_type";
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
    table[ "+COPN" ]             = new FsoGsm.PlusCOPN();
    table[ "+FCLASS" ]           = new FsoGsm.PlusFCLASS();
    table[ "+GCAP" ]             = new FsoGsm.PlusGCAP();

    // access control
    table[ "+CLCK" ]             = new FsoGsm.PlusCLCK();
    table[ "+CPIN" ]             = new FsoGsm.PlusCPIN();
    table[ "+CPWD" ]             = new FsoGsm.PlusCPWD();

    // URC only
    table[ "+CIEV" ]             = new FsoGsm.PlusCIEV();
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
    table[ "+CGREG" ]            = new FsoGsm.PlusCGREG();
    table[ "+CLIR" ]             = new FsoGsm.PlusCLIR();
    table[ "+CREG" ]             = new FsoGsm.PlusCREG();
    table[ "+COPS" ]             = new FsoGsm.PlusCOPS();
    table[ "+CSQ" ]              = new FsoGsm.PlusCSQ();
    table[ "+CSSI" ]             = new FsoGsm.PlusCSSI();
    table[ "+CSSU" ]             = new FsoGsm.PlusCSSU();
    table[ "+CUSD" ]             = new FsoGsm.PlusCUSD();
    table[ "+CCFC" ]             = new FsoGsm.PlusCCFC();

    // call control
    table[ "A" ]                 = new FsoGsm.V250A();
    table[ "H" ]                 = new FsoGsm.V250H();
    table[ "D" ]                 = new FsoGsm.V250D();
    table[ "+CEER" ]             = new FsoGsm.PlusCEER();
    table[ "+CHLD" ]             = new FsoGsm.PlusCHLD();
    table[ "+CLCC" ]             = new FsoGsm.PlusCLCC();
    table[ "+VTS" ]              = new FsoGsm.PlusVTS();
    table[ "+CTFR" ]             = new FsoGsm.PlusCTFR();

    // phonebook
    table[ "+CPBR" ]             = new FsoGsm.PlusCPBR();
    table[ "+CPBS" ]             = new FsoGsm.PlusCPBS();
    table[ "+CPBW" ]             = new FsoGsm.PlusCPBW();

    // sms
    table[ "+CDS" ]              = new FsoGsm.PlusCDS();
    table[ "+CMGD" ]             = new FsoGsm.PlusCMGD();
    table[ "+CMGL" ]             = new FsoGsm.PlusCMGL();
    table[ "+CMGR" ]             = new FsoGsm.PlusCMGR();
    table[ "+CMGS" ]             = new FsoGsm.PlusCMGS();
    table[ "+CMGW" ]             = new FsoGsm.PlusCMGW();
    table[ "+CMMS" ]             = new FsoGsm.PlusCMMS();
    table[ "+CMSS" ]             = new FsoGsm.PlusCMSS();
    table[ "+CMT" ]              = new FsoGsm.PlusCMT();
    table[ "+CMTI" ]             = new FsoGsm.PlusCMTI();
    table[ "+CNMA" ]             = new FsoGsm.PlusCNMA();
    table[ "+CPMS" ]             = new FsoGsm.PlusCPMS();
    table[ "+CSCA" ]             = new FsoGsm.PlusCSCA();

    // cell broadcast
    table[ "+CBM" ]              = new FsoGsm.PlusCBM();
    table[ "+CSCB" ]             = new FsoGsm.PlusCSCB();

    // pdp
    table[ "+CGACT" ]            = new FsoGsm.PlusCGACT();
    table[ "+CGATT" ]            = new FsoGsm.PlusCGATT();
    table[ "+CGDCONT" ]          = new FsoGsm.PlusCGDCONT();

    // misc
    table[ "+CMICKEY" ]          = new FsoGsm.PlusCMICKEY();
}

} /* namespace FsoGsm */

// vim:ts=4:sw=4:expandtab
