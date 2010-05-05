/*
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

using FsoGsm;
using Gee;

namespace TiCalypso
{

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
            re = new Regex( """%CSQ:  (?P<signal>\d+), (?:\d+), \d""" );
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail, if invalid
        }
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        strength = Constants.instance().networkSignalToPercentage( to_int( "signal" ) );
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
    public int arfcn[6];
    public int c1[6];
    public int c2[6];
    public int rxlev[6];
    public int bsic[6];
    public int cid[6];
    public int lac[6];
    public int foffset[6];
    public int timea[6];
    public int cba[6];
    public int cbq[6];
    public int ctype[6];
    public int rac[6];
    public int roffset[6];
    public int toffset[6];
    public int rxlevam[6];

    public PercentEM23()
    {
        try
        {
            re = new Regex( """%EM: (?P<val1>\d+),(?P<val2>\d+),(?P<val3>\d+),(?P<val4>\d+),(?P<val5>\d+),(?P<val6>\d+)""" );
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail, if invalid
        }
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
    }

    public string query()
    {
        return "%EM=2,3";
    }
}

/**
 * Register all custom commands
 **/
public void registerCustomAtCommands( HashMap<string,AtCommand> table )
{
    table[ "%CPRI" ]              = new PercentCPRI();
    table[ "%CSTAT" ]             = new PercentCSTAT();
    table[ "%CSQ" ]               = new PercentCSQ();

    table[ "%EM21" ]              = new PercentEM21();
    table[ "%EM23" ]              = new PercentEM23();
}

} /* namespace TiCalypso */
