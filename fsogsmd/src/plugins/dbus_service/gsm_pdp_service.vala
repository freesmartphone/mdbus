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

using GLib;

public class FsoGsm.GsmPdpService : FreeSmartphone.GSM.PDP, Service
{
    //
    // DBUS (org.freesmartphone.GSM.PDP.*)
    //

    public async bool get_roaming_allowed () throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, GLib.DBusError, GLib.IOError
    {
        checkAvailability();
        return modem.data().roamingAllowed;
    }

    public async void set_roaming_allowed (bool state) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, GLib.DBusError, GLib.IOError
    {
        checkAvailability();
        modem.data().roamingAllowed = state;
        yield modem.pdphandler.syncStatus();
    }

    public async void activate_context() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        var m = modem.createMediator<FsoGsm.PdpActivateContext>();
        yield m.run();
    }

    public async void deactivate_context() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        var m = modem.createMediator<FsoGsm.PdpDeactivateContext>();
        yield m.run();
    }

    public async void get_context_status( out FreeSmartphone.GSM.ContextStatus status, out GLib.HashTable<string,GLib.Variant> properties ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        status = modem.pdphandler.status;
        properties = modem.pdphandler.properties;
    }

    public async void get_credentials( out string apn, out string username, out string password ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.PdpGetCredentials>();
        yield m.run();
        apn = m.apn;
        username = m.username;
        password = m.password;
    }

    public async void internal_status_update( string status, GLib.HashTable<string,GLib.Variant> properties ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        yield modem.pdphandler.statusUpdate( status, properties );
    }

    public async void set_credentials( string apn, string username, string password ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.PdpSetCredentials>();
        yield m.run( apn, username, password );
    }
}

// vim:ts=4:sw=4:expandtab
