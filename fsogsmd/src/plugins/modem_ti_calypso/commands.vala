/*
 * Copyright (C) 2009-2012 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

using FsoGsm;
using Gee;

namespace TiCalypso
{

/**
 * %CPMB: SIM voice mailbox number
 **/
public class PercentCPMB : AbstractAtCommand
{
    public string number;

    public PercentCPMB()
    {
        try
        {
            re = new Regex( """%CPMB: (?P<id>\d),(?P<type>\d+),"(?P<number>[\+0-9*#w]*)",(?P<typ>\d+)(?:,"(?P<name>[^"]*)")?""" );
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail, if invalid
        }
        prefix = { "%CPMB: " };
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        number = Constants.phonenumberTupleToString( to_string( "number" ), to_int( "typ" ) );
    }

    public string query()
    {
        return "%CPMB=1";
    }
}

/**
 * %CPRI: GSM / PDP cipher indication
 **/
public class PercentCPRI : AbstractAtCommand
{
    public enum Status
    {
        DISABLED = 0,
        ENABLED  = 1,
        UNKNOWN  = 2
    }

    public Status telcipher;
    public Status pdpcipher;

    public PercentCPRI()
    {
        try
        {
            re = new Regex( """%CPRI: (?P<tel>[012]),(?P<pdp>[012])""" );
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail, if invalid
        }
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        telcipher = (Status) to_int( "tel" );
        pdpcipher = (Status) to_int( "pdp" );
    }
}

/**
 * %CSTAT: Subsystem readyness indication
 **/
public class PercentCSTAT : AbstractAtCommand
{
    public string subsystem;
    public bool ready;

    public PercentCSTAT()
    {
        try
        {
            re = new Regex( """%CSTAT: (?P<subsystem>[A-Z]+), (?P<ready>[01])""" );
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail, if invalid
        }
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        subsystem = to_string( "subsystem" );
        ready = to_int( "ready" ) == 1;
    }
}

/**
 * %CSQ: Signal strength indication
 **/
public class PercentCSQ : AbstractAtCommand
{
    public int strength;

    public PercentCSQ()
    {
        try
        {
            re = new Regex( """%CSQ: (?P<signal>\d+), (?:\d+), \d""" );
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail, if invalid
        }
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        strength = Constants.networkSignalToPercentage( to_int( "signal" ) );
    }
}

/**
 * %EM=2,1: Engineering Mode: Serving Cell Information
 **/
public class PercentEM21 : AbstractAtCommand
{
    public int arfcn;
    public int c1;
    public int c2;
    public int rxlev;
    public int bsic;
    public int cid;
    public int dsc;
    public int txlev;
    public int tn;
    public int rlt;
    public int tav;
    public int rxlev_f;
    public int rxlev_s;
    public int rxqual_f;
    public int rxqual_s;
    public int lac;
    public int cba;
    public int cbq;
    public int ctype;
    public int vocoder;

    public PercentEM21()
    {
        try
        {
            re = new Regex( """%EM: (?P<arfcn>\d+),(?P<c1>\d+),(?P<c2>\d+),(?P<rxlev>\d+),(?P<bsic>\d+),(?P<cid>\d+),(?P<dsc>\d+),(?P<txlev>\d+),(?P<tn>\d+),(?P<rlt>\d+),(?P<tav>\d+),(?P<rxlev_f>\d+),(?P<rxlev_s>\d+),(?P<rxqual_f>\d+),(?P<rxqual_s>\d+),(?P<lac>\d+),(?P<cba>\d+),(?P<cbq>\d+),(?P<ctype>\d+),(?P<vocoder>\d+)""" );
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail, if invalid
        }
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        arfcn = to_int( "arfcn" );
        c1 = to_int( "c1" );
        c2 = to_int( "c2" );
        rxlev = to_int( "rxlev" );
        bsic = to_int( "bsic" );
        cid = to_int( "cid" );
        dsc = to_int( "dsc" );
        txlev = to_int( "txlev" );
        tn = to_int( "tn" );
        rlt = to_int( "rlt" );
        tav = to_int( "tav" );
        rxlev_f = to_int( "rxlev_f" );
        rxlev_s = to_int( "rxlev_s" );
        rxqual_f = to_int( "rxqual_f" );
        rxqual_s = to_int( "rxqual_s" );
        lac = to_int( "lac" );
        cba = to_int( "cba" );
        cbq = to_int( "cbq" );
        ctype = to_int( "ctype" );
        vocoder = to_int( "vocoder" );
    }

    public string query()
    {
        return "%EM=2,1";
    }
}

/**
 * %EM=2,3: Engineering Mode: Neighbour Cell Information
 **/
public class PercentEM23 : AbstractAtCommand
{
    public int valid;

    public int[] arfcn;
    public int[] c1;
    public int[] c2;
    public int[] rxlev;
    public int[] bsic;
    public int[] cid;
    public int[] lac;
    public int[] foffset;
    public int[] timea;
    public int[] cba;
    public int[] cbq;
    public int[] ctype;
    public int[] rac;
    public int[] roffset;
    public int[] toffset;
    public int[] rxlevam;

    public PercentEM23()
    {
        try
        {
            re = new Regex( """(?P<val1>\d+),(?P<val2>\d+),(?P<val3>\d+),(?P<val4>\d+),(?P<val5>\d+),(?P<val6>\d+)""" );
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail, if invalid
        }

        length = 1 + 16;

    }

    public override void parseMulti( string[] response ) throws AtCommandError
    {
        if ( ! response[0].has_prefix( "%EM: " ) )
        {
            base.parse( response[0] );
        }
        else
        {
            var line0 = response[0].split( ":" );
            valid = line0[1].strip().to_int();
        }

        base.parse( response[1] );
        fillArray( ref arfcn, to_int( "val1" ), to_int( "val2" ), to_int( "val3" ), to_int( "val4" ), to_int( "val5" ), to_int( "val6" ) );
        base.parse( response[2] );
        fillArray( ref c1, to_int( "val1" ), to_int( "val2" ), to_int( "val3" ), to_int( "val4" ), to_int( "val5" ), to_int( "val6" ) );
        base.parse( response[3] );
        fillArray( ref c2, to_int( "val1" ), to_int( "val2" ), to_int( "val3" ), to_int( "val4" ), to_int( "val5" ), to_int( "val6" ) );
        base.parse( response[4] );
        fillArray( ref rxlev, to_int( "val1" ), to_int( "val2" ), to_int( "val3" ), to_int( "val4" ), to_int( "val5" ), to_int( "val6" ) );
        base.parse( response[5] );
        fillArray( ref bsic, to_int( "val1" ), to_int( "val2" ), to_int( "val3" ), to_int( "val4" ), to_int( "val5" ), to_int( "val6" ) );
        base.parse( response[6] );
        fillArray( ref cid, to_int( "val1" ), to_int( "val2" ), to_int( "val3" ), to_int( "val4" ), to_int( "val5" ), to_int( "val6" ) );
        base.parse( response[7] );
        fillArray( ref lac, to_int( "val1" ), to_int( "val2" ), to_int( "val3" ), to_int( "val4" ), to_int( "val5" ), to_int( "val6" ) );
        base.parse( response[8] );
        fillArray( ref foffset, to_int( "val1" ), to_int( "val2" ), to_int( "val3" ), to_int( "val4" ), to_int( "val5" ), to_int( "val6" ) );
        base.parse( response[9] );
        fillArray( ref timea, to_int( "val1" ), to_int( "val2" ), to_int( "val3" ), to_int( "val4" ), to_int( "val5" ), to_int( "val6" ) );
        base.parse( response[10] );
        fillArray( ref cba, to_int( "val1" ), to_int( "val2" ), to_int( "val3" ), to_int( "val4" ), to_int( "val5" ), to_int( "val6" ) );
        base.parse( response[11] );
        fillArray( ref cbq, to_int( "val1" ), to_int( "val2" ), to_int( "val3" ), to_int( "val4" ), to_int( "val5" ), to_int( "val6" ) );
        base.parse( response[12] );
        fillArray( ref ctype, to_int( "val1" ), to_int( "val2" ), to_int( "val3" ), to_int( "val4" ), to_int( "val5" ), to_int( "val6" ) );
        base.parse( response[13] );
        fillArray( ref rac, to_int( "val1" ), to_int( "val2" ), to_int( "val3" ), to_int( "val4" ), to_int( "val5" ), to_int( "val6" ) );
        base.parse( response[14] );
        fillArray( ref roffset, to_int( "val1" ), to_int( "val2" ), to_int( "val3" ), to_int( "val4" ), to_int( "val5" ), to_int( "val6" ) );
        base.parse( response[15] );
        fillArray( ref toffset, to_int( "val1" ), to_int( "val2" ), to_int( "val3" ), to_int( "val4" ), to_int( "val5" ), to_int( "val6" ) );
        base.parse( response[16] );
        fillArray( ref rxlevam, to_int( "val1" ), to_int( "val2" ), to_int( "val3" ), to_int( "val4" ), to_int( "val5" ), to_int( "val6" ) );
    }

    private void fillArray( ref int[] array, int v1, int v2, int v3, int v4, int v5, int v6 )
    {
        array = new int[] { v1, v2, v3, v4, v5, v6 };
    }

    public string query()
    {
        return "%EM=2,3";
    }
}

/**
 * %PVRF: SIM authentication counters
 **/
public class PercentPVRF : AbstractAtCommand
{
    public int pin;
    public int pin2;
    public int puk;
    public int puk2;

    public PercentPVRF()
    {
        try
        {
            re = new Regex( """%PVRF: (?P<pin>\d+), (?P<pin2>\d+), (?P<puk>\d+), (?P<puk2>\d+), (?P<locked>\d+), (?P<na4>-?\d+)""" );
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail, if invalid
        }
        prefix = { "%PVRF: " };
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        pin = to_int( "pin" );
        pin2 = to_int( "pin2" );
        puk = to_int( "puk" );
        puk2 = to_int( "puk2" );
    }

    public string query()
    {
        return "%PVRF?";
    }
}

/**
 * Register all custom commands
 **/
public void registerCustomAtCommands( HashMap<string,AtCommand> table )
{
    table[ "%CPMB" ]              = new PercentCPMB();

    table[ "%CPRI" ]              = new PercentCPRI();
    table[ "%CSTAT" ]             = new PercentCSTAT();
    table[ "%CSQ" ]               = new PercentCSQ();

    table[ "%EM21" ]              = new PercentEM21();
    table[ "%EM23" ]              = new PercentEM23();

    table[ "%PVRF" ]              = new PercentPVRF();
}

} /* namespace TiCalypso */

// vim:ts=4:sw=4:expandtab
