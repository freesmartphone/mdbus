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

public class FsoGsm.GsmVoiceMailService : FreeSmartphone.GSM.VoiceMail, Service
{
    //
    // DBUS (org.freesmartphone.GSM.VoiceMail.*)
    //

    public async string get_voice_mailbox_number() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.VoiceMailboxGetNumber>();
        yield m.run();
        return m.number;
    }

    public async void set_voice_mailbox_number( string number ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.VoiceMailboxSetNumber>();
        yield m.run( number );
    }

    public async string[] get_stored_voice_mails() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
        //var m = modem.createMediator<FsoGsm.VoiceMailboxGetRecordings>();
        //yield m.run( number );
    }
}

// vim:ts=4:sw=4:expandtab
