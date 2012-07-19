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

public class FsoGsm.GsmSimService : FreeSmartphone.GSM.SIM, Service
{
    //
    // DBUS (org.freesmartphone.GSM.SIM.*)
    //

    public async void change_auth_code( string old_pin, string new_pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_SIM_READY );
        var m = modem.createMediator<FsoGsm.SimChangeAuthCode>();
        yield m.run( old_pin, new_pin );
    }

    public async void delete_entry( string category, int index ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_SIM_READY );
        var m = modem.createMediator<FsoGsm.SimDeleteEntry>();
        yield m.run( category, index );
    }

    public async void delete_message( int index ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_SIM_READY );
        var m = modem.createMediator<FsoGsm.SimDeleteMessage>();
        yield m.run( index );
    }

    public async bool get_auth_code_required() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_SIM_READY );
        var m = modem.createMediator<FsoGsm.SimGetAuthCodeRequired>();
        yield m.run();
        return m.required;
    }

    public async FreeSmartphone.GSM.SIMAuthStatus get_auth_status() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.SimGetAuthStatus>();
        yield m.run();
        return m.status;
    }

    public async FreeSmartphone.GSM.SIMHomeZone[] get_home_zone_parameters() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_SIM_READY );
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async void get_phonebook_info( string category, out int slots, out int numberlength, out int namelength ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_SIM_READY );
        var m = modem.createMediator<FsoGsm.SimGetPhonebookInfo>();
        yield m.run( category, out slots, out numberlength, out namelength );
    }

    public async string get_service_center_number() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_SIM_READY );
        var m = modem.createMediator<FsoGsm.SimGetServiceCenterNumber>();
        yield m.run();
        return m.number;
    }

    public async GLib.HashTable<string,GLib.Variant> get_sim_info() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_SIM_LOCKED ); // or READY?
        var m = modem.createMediator<FsoGsm.SimGetInformation>();
        yield m.run();
        return m.info;
    }

    public async GLib.HashTable<string,GLib.Variant> get_unlock_counters() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_SIM_LOCKED );
        var m = modem.createMediator<FsoGsm.SimGetUnlockCounters>();
        yield m.run();
        return m.counters;
    }

    public async void retrieve_message( int index, out string status, out string number, out string contents, out GLib.HashTable<string,GLib.Variant> properties ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_SIM_READY );
        var m = modem.createMediator<FsoGsm.SimRetrieveMessage>();
        yield m.run( index, out status, out number, out contents, out properties );
    }

    public async FreeSmartphone.GSM.SIMEntry[] retrieve_phonebook( string category, int mindex, int maxdex ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_SIM_READY );
        var m = modem.createMediator<FsoGsm.SimRetrievePhonebook>();
        yield m.run( category, mindex, maxdex );
        return m.phonebook;
    }

    public async void send_auth_code( string pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_SIM_LOCKED );
        var m = modem.createMediator<FsoGsm.SimSendAuthCode>();
        yield m.run( pin );
    }

    public async string send_generic_sim_command( string command ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_SIM_READY );
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async string send_restricted_sim_command( int command, int fileid, int p1, int p2, int p3, string data ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_SIM_READY );
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async void send_stored_message( int index, out int transaction_index, out string timestamp ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        var m = modem.createMediator<FsoGsm.SimSendStoredMessage>();
        yield m.run( index );
        transaction_index = m.transaction_index;
        timestamp = m.timestamp;
    }

    public async void set_auth_code_required( bool check, string pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_SIM_READY );
        var m = modem.createMediator<FsoGsm.SimSetAuthCodeRequired>();
        yield m.run( check, pin );
    }

    public async void set_service_center_number( string number ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_SIM_READY );
        var m = modem.createMediator<FsoGsm.SimSetServiceCenterNumber>();
        yield m.run( number );
    }

    public async void store_entry( string category, int index, string name, string number ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_SIM_READY );
        var m = modem.createMediator<FsoGsm.SimWriteEntry>();
        yield m.run( category, index, number, name );
    }

    public async int store_message( string recipient_number, string contents, GLib.HashTable<string,GLib.Variant> properties ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_SIM_READY );
        var m = modem.createMediator<FsoGsm.SimStoreMessage>();
        yield m.run( recipient_number, contents, false );
        return m.memory_index;
    }

    public async void unlock( string puk, string new_pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_SIM_LOCKED );
        var m = modem.createMediator<FsoGsm.SimUnlock>();
        yield m.run( puk, new_pin );
    }
}

// vim:ts=4:sw=4:expandtab
