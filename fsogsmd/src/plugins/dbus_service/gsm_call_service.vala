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

public class FsoGsm.GsmCallService : FreeSmartphone.GSM.Call, Service
{
    //
    // DBUS (org.freesmartphone.GSM.Call.*)
    //

    public async void activate( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        var m = modem.createMediator<FsoGsm.CallActivate>();
        yield m.run( id );
    }

    public async void activate_conference( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async void emergency( string number ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async void hold_active() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        var m = modem.createMediator<FsoGsm.CallHoldActive>();
        yield m.run();
    }

    public async int initiate( string number, string ctype ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        var m = modem.createMediator<FsoGsm.CallInitiate>();
        yield m.run( number, ctype );
        return m.id;
    }

    public async void join() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async FreeSmartphone.GSM.CallDetail[] list_calls() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        var m = modem.createMediator<FsoGsm.CallListCalls>();
        yield m.run();
        return m.calls;
    }

    public async void release( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        var m = modem.createMediator<FsoGsm.CallRelease>();
        yield m.run( id );
    }

    public async void release_all() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        var m = modem.createMediator<FsoGsm.CallReleaseAll>();
        yield m.run();
    }

    public async void release_held() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async void send_dtmf( string tones ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        var m = modem.createMediator<FsoGsm.CallSendDtmf>();
        yield m.run( tones );
    }

    public async void transfer() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        var m = modem.createMediator<FsoGsm.CallTransfer>();
        yield m.run();
    }

    public async void deflect( string number ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        var m = modem.createMediator<FsoGsm.CallDeflect>();
        yield m.run( number );
    }
}

// vim:ts=4:sw=4:expandtab
