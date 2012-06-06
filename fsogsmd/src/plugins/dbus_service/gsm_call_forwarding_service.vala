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

    public string voice_busy { owned get { return ""; } }
    public string voice_no_reply { owned get { return ""; } }
    public int voice_no_reply_timeout { get { return 0; } }
    public string voice_not_reachable { owned get { return ""; } }
    public string voice_unconditional { owned get { return ""; } }

    public async void disable_all( string type ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
    }

    public async void enable( string rule, string number, int time ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
    }

    public async void disable( string rule ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
    }
}

// vim:ts=4:sw=4:expandtab
