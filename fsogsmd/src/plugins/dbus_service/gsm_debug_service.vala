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

public class FsoGsm.GsmDebugService : FreeSmartphone.GSM.Debug, Service
{
    //
    // DBUS (org.freesmartphone.GSM.Debug.*)
    //

    public async string debug_command( string command, string channel )
        throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.DebugCommand>();
        yield m.run( command, channel );
        return m.response;
    }

    public async void debug_inject_response( string response, string channel )
        throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.DebugInjectResponse>();
        yield m.run( response, channel );
    }

    public async void debug_ping()
        throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.DebugPing>();
        yield m.run();
    }
}

// vim:ts=4:sw=4:expandtab
