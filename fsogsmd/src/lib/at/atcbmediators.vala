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
 * This file contains Dbus/AT command mediators only using official 3GPP AT commands.
 *
 * Do _not_ add vendor-specific mediators here, instead add them to your modem plugin.
 **/

using Gee;

namespace FsoGsm {

/**
 * CB Mediators
 **/
public class AtCbSetCellBroadcastSubscriptions : CbSetCellBroadcastSubscriptions
{
    public override async void run( string subscriptions ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        if ( ! ( subscriptions in new string[] { "none", "all" } ) )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Must use 'none' or 'all' as parameter." );
        }
        var cmd = modem.createAtCommand<PlusCSCB>( "+CSCB" );
        var response = yield modem.processAtCommandAsync( cmd, cmd.issue( subscriptions == "all" ? PlusCSCB.Mode.ALL : PlusCSCB.Mode.NONE ) );
        checkResponseOk( cmd, response );
    }
}

public class AtCbGetCellBroadcastSubscriptions : CbGetCellBroadcastSubscriptions
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = modem.createAtCommand<PlusCSCB>( "+CSCB" );
        var response = yield modem.processAtCommandAsync( cmd, cmd.query() );
        checkResponseValid( cmd, response );
        if ( cmd.mode == PlusCSCB.Mode.ALL )
        {
            subscriptions = "all";
        }
        else
        {
            subscriptions = "none";
        }
    }
}

} // namespace FsoGsm

// vim:ts=4:sw=4:expandtab
