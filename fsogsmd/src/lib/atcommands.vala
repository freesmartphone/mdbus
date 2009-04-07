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

namespace FsoGsm
{

public class PlusCGMM : AbstractAtCommand
{
    public string model;

    public PlusCGMM()
    {
        re = new Regex( """(\+CGMM:\ )?"?(?P<model>[^"]*)"?""" );
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        model = to_string( "model" );
    }

    public string query()
    {
        return "+CGMM";
    }
}

public class PlusCGMI : AbstractAtCommand
{
    public string manufacturer;

    public PlusCGMI()
    {
        re = new Regex( """(\+CGMI:\ )?"?(?P<manufacturer>[^"]*)"?""" );
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        manufacturer = to_string( "manufacturer" );
    }

    public string query()
    {
        return "+CGMI";
    }
}

public class PlusCOPS_Test : AbstractAtCommand
{
    public struct Info
    {
        public int status;
        public string shortname;
        public string longname;
        public string mccmnc;
    }
    public List<Info?> info;

    public PlusCOPS_Test()
    {
        re = new Regex( """\((?<status>\d),"(?P<longname>[^"]*)","(?P<shortname>[^"]*)","(?P<mccmnc>[^"]*)"\)""" );
        prefix = { "+COPS: " };
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        info = new List<Info?>();
        do
        {
            var i = Info() { status = to_int( "status" ),
                             longname = to_string( "longname" ),
                             shortname = to_string( "shortname" ),
                             mccmnc = to_string( "mccmnc" ) };
            info.append( i );
        }
        while ( mi.next() );
    }

    public string issue()
    {
        return "+COPS=?";
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
        return "+COPS?";
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
}

public class PlusCGCLASS : AbstractAtCommand
{
    public string gprsclass;

    public PlusCGCLASS()
    {
        re = new Regex( """\+CGCLASS:\ "?(?P<gprsclass>[^"]*)"?""" );
        prefix = { "+CGCLASS: " };
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        gprsclass = to_string( "gprsclass" );
    }

    public string query()
    {
        return "+CGCLASS?";
    }
}

public class PlusCFUN : AbstractAtCommand
{
    public int fun;

    public PlusCFUN()
    {
        re = new Regex( """\+CFUN:\ (?P<fun>\d)""" );
        prefix = { "+CFUN: " };
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        fun = to_int( "fun" );
    }

    public string issue( int fun )
    {
        return "+CFUN=%d".printf( fun );
    }

    public string query()
    {
        return "+CFUN?";
    }

    public string test()
    {
        return "+CFUN=?";
    }
}

public class PlusCOPS : AbstractAtCommand
{
    public int status;
    public int mode;
    public string oper;

    public PlusCOPS()
    {
        re = new Regex( """\+COPS:\ (?P<status>\d)(,(?P<mode>\d)?(,"(?P<oper>[^"]*)")?)?""" );
        prefix = { "+COPS: " };
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        status = to_int( "status" );
        mode = to_int( "mode" );
        oper = to_string( "oper" );
    }

    public string issue( int mode, int format, int oper = 0 )
    {
        if ( oper == 0 )
            return "+CFUN=%d,%d".printf( mode, format );
        else
            return "+CFUN=%d,%d,\"%d\"".printf( mode, format, oper );
    }

    public string query()
    {
        return "+COPS?";
    }
}

public class PlusCGSN : AbstractAtCommand
{
    public string imei;

    public PlusCGSN()
    {
        re = new Regex( """(\+CGSN:\ )?"?(?P<imei>[^"]*)"?""" );
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        imei = to_string( "imei" );
    }

    public string query()
    {
        return "+CGSN";
    }
}

public class PlusCGMR : AbstractAtCommand
{
    public string revision;

    public PlusCGMR()
    {
        re = new Regex( """(\+CGMR:\ )?"?(?P<revision>[^"]*)"?""" );
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        revision = to_string( "revision" );
    }

    public string query()
    {
        return "+CGMR";
    }
}

public void registerGenericAtCommands( GLib.HashTable<string, AtCommand> table )
{
    // register commands
    table.insert( "+CGMM",           new FsoGsm.PlusCGMM() );
    table.insert( "+CGMI",           new FsoGsm.PlusCGMI() );
    table.insert( "+COPS=?",         new FsoGsm.PlusCOPS_Test() );
    table.insert( "+CPIN",           new FsoGsm.PlusCPIN() );
    table.insert( "+FCLASS",         new FsoGsm.PlusFCLASS() );
    table.insert( "+CGCLASS",        new FsoGsm.PlusCGCLASS() );
    table.insert( "+CFUN",           new FsoGsm.PlusCFUN() );
    table.insert( "+COPS",           new FsoGsm.PlusCOPS() );
    table.insert( "+CGSN",           new FsoGsm.PlusCGSN() );
    table.insert( "+CGMR",           new FsoGsm.PlusCGMR() );
}

} /* namespace FsoGsm */
