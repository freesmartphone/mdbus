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

using GLib;

public class FsoGsm.GsmCbService : FreeSmartphone.GSM.CB, Service
{
    //
    // DBUS (org.freesmartphone.GSM.CB.*)
    //

    public async string get_cell_broadcast_subscriptions()
        throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        var m = modem.createMediator<FsoGsm.CbGetCellBroadcastSubscriptions>();
        yield m.run();
        return m.subscriptions;
    }

    public async void set_cell_broadcast_subscriptions( string subscriptions )
        throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        var m = modem.createMediator<FsoGsm.CbSetCellBroadcastSubscriptions>();
        yield m.run( subscriptions );
    }
}

// vim:ts=4:sw=4:expandtab
