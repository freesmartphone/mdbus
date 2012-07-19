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

public class FsoGsm.GsmNetworkService : FreeSmartphone.GSM.Network, Service
{
    //
    // DBUS (org.freesmartphone.GSM.Network.*)
    //

    public async void disable_call_forwarding( string reason, string class_ )
        throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async void enable_call_forwarding( string reason, string class_, string number, int timeout )
        throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async GLib.HashTable<string,GLib.Variant> get_call_forwarding( string reason )
        throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async FreeSmartphone.GSM.CallingIdentificationStatus get_calling_identification()
        throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        var m = modem.createMediator<FsoGsm.NetworkGetCallingId>();
        yield m.run();
        return m.status;
    }

    public async void get_time_report( out int time, out int timestamp, out int zone, out int zonestamp )
        throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var ltr = modem.data().networkTimeReport;
        time = ltr.time;
        timestamp = ltr.timestamp;
        zone = ltr.zone;
        zonestamp = ltr.zonestamp;
    }

    public async int get_signal_strength() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        var m = modem.createMediator<FsoGsm.NetworkGetSignalStrength>();
        yield m.run();
        return m.signal;
    }

    public async GLib.HashTable<string,GLib.Variant> get_status()
        throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.NetworkGetStatus>();
        yield m.run();
        return m.status;
    }

    public async FreeSmartphone.GSM.NetworkProvider[] list_providers()
        throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.NetworkListProviders>();
        yield m.run();
        return m.providers;
    }

    public async void register_() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.NetworkRegister>();
        yield m.run();
    }

    public async void register_with_provider( string operator_code )
        throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.NetworkRegisterWithProvider>();
        yield m.run( operator_code );
    }

    public async void send_ussd_request( string request )
        throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        var m = modem.createMediator<FsoGsm.NetworkSendUssdRequest>();
        yield m.run( request );
    }

    public async void set_calling_identification( FreeSmartphone.GSM.CallingIdentificationStatus status )
        throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        var m = modem.createMediator<FsoGsm.NetworkSetCallingId>();
        yield m.run( status );
    }

    public async void unregister() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        var m = modem.createMediator<FsoGsm.NetworkUnregister>();
        yield m.run();
    }
}

// vim:ts=4:sw=4:expandtab
