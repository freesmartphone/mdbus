/**
 * Copyright (C) 2012 Simon Busch <morphis@gravedo.de>
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

HashMap<string,FsoGsm.AtCommand> commands;

void setup()
{
    // Take care we have a valid modem which is used by the commands to access it's logger object
    FsoGsm.theModem = new FsoGsm.NullModem();

    commands = new HashMap<string,FsoGsm.AtCommand>();
    Gtm601.registerCustomAtCommands( commands );
}

AtCommand atCommandFactory( string command )
{
    assert( commands != null );
    AtCommand? cmd = commands[ command ];
    assert( cmd != null );
    return cmd;
}

void test_option_gtm601_atcommand_PlusCEER()
{
    var cmd = (Gtm601.PlusCEER) atCommandFactory( "+CEER" );
    cmd.parse( "+CEER: Normal call clearing" );

    assert( cmd.reason == "Normal call clearing" );
}

void main( string[] args )
{
    Test.init( ref args );
    setup();
    Test.add_func( "/Option/Gtm601/AtCommand/+CEER", test_option_gtm601_atcommand_PlusCEER );
    Test.run();
}

// vim:ts=4:sw=4:expandtab
