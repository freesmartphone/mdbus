/*
 * Copyright (C) 2010-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

using Gee;
using FsoGsm;
using GIsiComm;

namespace NokiaIsi
{
/*
 * org.freesmartphone.GSM.Debug
 */

public class IsiDebugCommand : DebugCommand
{
    public override async void run( string command, string category ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        if ( ! ( command in new string[] { "MTC", "SIM", "SIMAUTH", "NET", "CALL", "PHONEINFO" } ) )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( @"Subsystem $command not known" );
        }

        var req = new uint8[] {};

        foreach ( var byte in category.split( " " ) )
        {
            uint8 b = 0;
            if ( 0 == byte.scanf( "%X", &b ) )
            {
                throw new FreeSmartphone.Error.INVALID_PARAMETER( @"Can't parse $byte in command" );
            }

            req += b;
        }

        GIsiComm.AbstractBaseClient client = null;
        if ( command == "MTC" ) client = NokiaIsi.isimodem.mtc;
        else if ( command == "SIM" ) client = NokiaIsi.isimodem.sim;
        else if ( command == "SIMAUTH" ) client = NokiaIsi.isimodem.simauth;
        else if ( command == "NET" ) client = NokiaIsi.isimodem.net;
        else if ( command == "CALL" ) client = NokiaIsi.isimodem.call;
        else if ( command == "PHONEINFO" ) client = NokiaIsi.isimodem.info;

        client.sendGenericRequest( req, (error, answer) => {
            if ( error == ErrorCode.OK )
            {
                response = FsoFramework.StringHandling.hexdump( answer );
            }
            else
            {
                response = "<ISI COMMUNICATION ERROR>";
            }
            run.callback();
        } );
        yield;
    }
}

} // namespace NokiaIsi

// vim:ts=4:sw=4:expandtab
