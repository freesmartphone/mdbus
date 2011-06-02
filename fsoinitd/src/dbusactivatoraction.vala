/**
 * Copyright (C) 2010 Simon Busch <morphis@gravedo.de>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 */

namespace FsoInit {

public class DBusActivatorAction : IAction, GLib.Object
{
    public string name { get { return "DBusActivatorAction"; } }

    public string service_name { get; set; default = ""; }
    public bool use_system_bus { get; set; default = true; }
    public string object_name { get; set; default = ""; }
    public string object_path { get; set; default = ""; }
    public string iface { get; set; default = ""; }

    public DBusActivatorAction.with_settings(string service_name,
                                             bool use_system_bus,
                                             string object_name,
                                             string object_path,
                                             string iface)
    {
        this.service_name = service_name;
        this.use_system_bus = use_system_bus;
        this.object_name = object_name;
        this.object_path = object_path;
        this.iface = iface;
    }

    public string to_string()
    {
        var res = @"[$(name)] :: ";
        if (use_system_bus)
            res += @"bus_type=SYSTEM ";
        else res += @"bus_type=SESSION ";
        res += @"object_name='$(object_name)' ";
        res += @"object_path='$(object_path)' ";
        res += @"iface='$(iface)' ";
        return res;
    }

    public bool run()
    {
        try
        {
            var bus_type = use_system_bus ? DBus.BusType.SYSTEM : DBus.BusType.SESSION;
            var conn = DBus.Bus.get(bus_type);
            var obj = conn.get_object(object_name, object_path, iface);

            if (obj == null) { /* FIXME */ }
            // FIXME maybe call the Ping() function?
        }
        catch (DBus.Error err)
        {
            FsoFramework.theLogger.error(@"Could not activate dbus service '$(service_name)'");
            return false;
        }

        return true;
    }

    public bool reset()
    {
        return true;
    }
}

} // namespace

// vim:ts=4:sw=4:expandtab

