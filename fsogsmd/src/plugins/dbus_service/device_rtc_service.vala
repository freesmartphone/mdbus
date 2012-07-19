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

public class FsoGsm.DeviceRtcService : FreeSmartphone.Device.RealtimeClock, Service
{
    //
    // DBUS (org.freesmartphone.Device.RealtimeClock)
    //

    public async int get_current_time() throws FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.DeviceGetCurrentTime>();
        try
        {
            yield m.run();
        }
        catch ( FreeSmartphone.GSM.Error e )
        {
            throw new FreeSmartphone.Error.SYSTEM_ERROR( e.message );
        }
        return m.since_epoch;
    }

    public async void set_current_time( int seconds_since_epoch ) throws FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.DeviceSetCurrentTime>();
        try
        {
            yield m.run( seconds_since_epoch );
        }
        catch ( FreeSmartphone.GSM.Error e )
        {
            throw new FreeSmartphone.Error.SYSTEM_ERROR( e.message );
        }
    }

    public async int get_wakeup_time() throws FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.DeviceGetAlarmTime>();
        try
        {
            yield m.run();
        }
        catch ( FreeSmartphone.GSM.Error e )
        {
            throw new FreeSmartphone.Error.SYSTEM_ERROR( e.message );
        }
        return m.since_epoch;
    }

    public async void set_wakeup_time( int seconds_since_epoch ) throws FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.DeviceSetAlarmTime>();
        try
        {
            yield m.run( seconds_since_epoch );
        }
        catch ( FreeSmartphone.GSM.Error e )
        {
            throw new FreeSmartphone.Error.SYSTEM_ERROR( e.message );
        }
        this.wakeup_time_changed( seconds_since_epoch ); // DBUS SIGNAL
    }
}

// vim:ts=4:sw=4:expandtab
