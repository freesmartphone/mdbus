/*
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

public class FsoGsm.GsmCallForwardingService : FreeSmartphone.GSM.CallForwarding, Service
{
    //
    // DBUS (org.freesmartphone.GSM.CallForwarding.*)
    //

    public async void disable_all() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        var m = modem.createMediator<FsoGsm.CallForwardingDisableAll>();
        yield m.run();
    }

    public async void enable( string cls, string reason, string number, int time ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        var m = modem.createMediator<FsoGsm.CallForwardingEnable>();
        yield m.run( cls, reason, number, time );
    }

    public async void disable( string cls, string reason ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        var m = modem.createMediator<FsoGsm.CallForwardingDisable>();
        yield m.run( cls, reason );
    }
}

// vim:ts=4:sw=4:expandtab
