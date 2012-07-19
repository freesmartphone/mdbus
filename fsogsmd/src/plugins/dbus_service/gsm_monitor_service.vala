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

public class FsoGsm.GsmMonitorService : FreeSmartphone.GSM.Monitor, Service
{
    //
    // DBUS (org.freesmartphone.GSM.Monitor.*)
    //

    public async GLib.HashTable<string,GLib.Variant> get_serving_cell_information()
        throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.MonitorGetServingCellInformation>();
        yield m.run();
        return m.cell;
    }

    public async GLib.HashTable<string,GLib.Variant>[] get_neighbour_cell_information()
        throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.MonitorGetNeighbourCellInformation>();
        yield m.run();
        return m.cells;
    }
}

// vim:ts=4:sw=4:expandtab
