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
 * This file contains Dbus/AT command mediators only using official 3GPP AT commands.
 *
 * Do _not_ add vendor-specific mediators here, instead add them to your modem plugin.
 **/

public class FsoGsm.DeviceGetAntennaPower : FsoGsm.AbstractMediator
{
    public DeviceGetAntennaPower()
    {
        debug( "DeviceGetAntennaPower()" );
        enqueue( FsoGsm.theModem.atCommandFactory( "PlusCFUN" ), onResponse );
    }
    public void onResponse( FsoGsm.AtCommand command, string response )
    {
        debug( "DeviceGetAntennaPower.onResponse( '%s' )", response );

        var cmd = command as FsoGsm.PlusCFUN;
        cmd.parse( response );

        debug( "calling dbus release with '%d'", cmd.fun );

    }
}

