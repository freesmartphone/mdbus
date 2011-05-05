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

using FsoGsm;
using Gee;

namespace QualcommHtc
{

/**
 * +HTCCTZV: "10/05/02,15:27:30+08,1"
 **/
public class PlusHTCCTZV : AbstractAtCommand
{
    public int year;
    public int month;
    public int day;
    public int hour;
    public int minute;
    public int second;
    public int tzoffset; // in minutes against UTC

    public PlusHTCCTZV()
    {
        try
        {
            var str = """\+HTCCTZV: "?(?P<year>\d?\d)/(?P<month>\d?\d)/(?P<day>\d?\d),(?P<hour>\d?\d):(?P<minute>\d?\d):(?P<second>\d?\d)(?P<sign>[\+-])(?P<tzoffset>\d\d)?,1"?"""";
            re = new Regex( str );
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail, if invalid
        }
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        year = 2000 + to_int( "year" );
        month = to_int( "month" );
        day = to_int( "day" );
        hour = to_int( "hour" );
        minute = to_int( "minute" );
        second = to_int( "second" );
        tzoffset = to_int( "tzoffset" ) * 15;
        if ( to_string( "sign" ) == "-" )
        {
            tzoffset = -tzoffset;
        }
    }
}

public class MyPlusCEER : FsoGsm.PlusCEER
{
    public MyPlusCEER()
    {
        try
        {
            re = new Regex( """\+CEER: (?P<reason>[A-Z a-z]+)""" );
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
        var r = to_string( "reason" );

        if ( "Call rejected" in r )
        {
            reason = "local-reject";
        }
        else if ( "Client ended call" in r )
        {
            reason = "local-cancel";
        }
        else if ( "Network ended call" in r )
        {
            reason = "remote-cancel";
        }
        else
        {
            theModem.logger.info( @"Unknown +CEER cause '$r'; please report to Mickey <smartphones-userland@linuxtogo.org>" );
        }
    }
}


/**
 * Register all custom commands
 **/
public void registerCustomAtCommands( HashMap<string,AtCommand> table )
{
    table[ "+HTCCTZV" ]           = new PlusHTCCTZV();

    table[ "+CEER" ]              = new MyPlusCEER();
}

} /* namespace QualcommHtc */

// vim:ts=4:sw=4:expandtab
