/*
 * File Name:
 * Creation Date: 23-08-2009
 * Last Modified:
 *
 * Authored by Frederik 'playya' Sdun <Frederik.Sdun@googlemail.com>
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
 *
 */
using GLib;
using DBus;

namespace DBus
{
    [DBus (name = "org.freedesktop.DBus")]
    public interface Service : GLib.Object
    {
        public abstract string hello() throws DBus.Error;
        public abstract uint request_name(string param0, uint param1) throws DBus.Error;
        public abstract uint release_name(string param0) throws DBus.Error;
        public abstract uint start_service_by_name(string param0, uint param1) throws DBus.Error;
        public abstract void update_activation_environment(GLib.HashTable<string, string> param0) throws DBus.Error;
        public abstract bool name_has_owner(string param0) throws DBus.Error;
        public abstract string[] list_names() throws DBus.Error;
        public abstract string[] list_activatable_names() throws DBus.Error;
        public abstract void add_match(string param0) throws DBus.Error;
        public abstract void remove_match(string param0) throws DBus.Error;
        public abstract string get_name_owner(string param0) throws DBus.Error;
        public abstract string[] list_queued_owners(string param0) throws DBus.Error;
        public abstract uint get_connection_unix_user(string param0) throws DBus.Error;
        public abstract uint get_connection_unix_process_i_d(string param0) throws DBus.Error;
        public abstract uchar[] get_adt_audit_session_data(string param0) throws DBus.Error;
        public abstract uchar[] get_connection_s_e_linux_security_context(string param0) throws DBus.Error;
        public abstract void reload_config() throws DBus.Error;
        public abstract string get_id() throws DBus.Error;
        public signal void name_owner_changed(string param0, string param1, string param2);
        public signal void name_lost(string param0);
        public signal void name_acquired(string param0);
    }
    public const string DBUS_PATH = "/org/freedesktop/DBus";
    public const string DBUS_BUS = "org.freedesktop.DBus";
}
