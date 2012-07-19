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

public class FsoGsm.GsmSmsService : FreeSmartphone.GSM.SMS, Service
{
    //
    // DBUS (org.freesmartphone.GSM.SMS.*)
    //

    public async uint get_size_for_text_message( string contents )
        throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.SmsGetSizeForTextMessage>();
        yield m.run( contents );
        return m.size;
    }

    public async FreeSmartphone.GSM.SIMMessage[] retrieve_text_messages()
        throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_SIM_READY );
        var m = modem.createMediator<FsoGsm.SmsRetrieveTextMessages>();
        yield m.run();
        return m.messagebook;
    }

    public async void send_text_message( string recipient_number, string contents, bool want_report,
        out int transaction_index, out string timestamp )
        throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        var m = modem.createMediator<FsoGsm.SmsSendTextMessage>();
        yield m.run( recipient_number, contents, want_report );
        transaction_index = m.transaction_index;
        timestamp = m.timestamp;
    }
}

// vim:ts=4:sw=4:expandtab
