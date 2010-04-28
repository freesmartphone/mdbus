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
            re = new Regex( """%CPRI: (?P<tel>[012]), (?P<pdp>[012])""" );
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
        strength = Constants.instance().networkSignalToPercentage( to_int( "signal" ) );
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
}

} /* namespace TiCalypso */
