/*
 * (C) 2012 Simon Busch <morphis@gravedo.de>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 */

namespace Phonesim
{
    [DBus (name = "org.ofono.phonesim.Script", timeout = 120000)]
    public interface ScriptManager : GLib.Object
    {
        [DBus (name = "SetPath")]
        public abstract async void set_path( string path ) throws GLib.Error, GLib.IOError, GLib.DBusError;
        [DBus (name = "GetPath")]
        public abstract async string get_path() throws GLib.Error, GLib.IOError, GLib.DBusError;
        [DBus (name = "Run")]
        public abstract async string run( string name ) throws GLib.Error, GLib.IOError, GLib.DBusError;
    }
}

// vim:ts=4:sw=4:expandtab
