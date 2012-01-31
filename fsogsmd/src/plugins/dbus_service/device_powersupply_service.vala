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

public class FsoGsm.DevicePowerSupplyService : FreeSmartphone.Device.PowerSupply, Service
{
    //
    // DBUS (org.freesmartphone.Device.PowerSupply.*)
    //

    public async FreeSmartphone.Device.PowerStatus get_power_status() throws DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.DeviceGetPowerStatus>();
        try
        {
            yield m.run();
            return m.status;
        }
        catch ( GLib.Error e ) // get_power_status() should not raise any errors
        {
            return FreeSmartphone.Device.PowerStatus.UNKNOWN;
        }
    }

    public async int get_capacity() throws DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.DeviceGetPowerStatus>();
        try
        {
            yield m.run();
            return m.level;
        }
        catch ( GLib.Error e ) // get_capacity() should not raise any errors
        {
            return -1;
        }
    }

}

// vim:ts=4:sw=4:expandtab
