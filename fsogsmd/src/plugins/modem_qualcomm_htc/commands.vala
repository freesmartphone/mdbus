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
    public int sign;
    public int tzoffset;

    public PlusHTCCTZV()
    {
        try
        {
            var str = """\+HTCCTZV: "?(?P<year>\d?\d)/(?P<month>\d?\d)/(?P<day>\d?\d),(?P<hour>\d?\d):(?P<minute>\d?\d):(?P<second>\d?\d)(?P<sign>[\+-])(?P<tzoffset>\d\d))?"""";
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
        year = to_int( "year" );
        month = to_int( "month" );
        day = to_int( "day" );
        hour = to_int( "hour" );
        minute = to_int( "minute" );
        second = to_int( "second" );
        sign = to_string( "sign" ) == "+" ? 1 : -1;
        tzoffset = to_int( "tzoffset" );
    }
}

/**
 * Register all custom commands
 **/
public void registerCustomAtCommands( HashMap<string,AtCommand> table )
{
    table[ "+HTCCTZV" ]           = new PlusHTCCTZV();
}

} /* namespace QualcommHtc */
