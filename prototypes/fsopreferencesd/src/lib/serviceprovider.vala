/*
 * Copyright (C) 2011 Simon Busch <morphis@gravedo.de>
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

namespace FsoPreferences
{
    public abstract class ServiceProvider
        : FsoFramework.AbstractObject, FreeSmartphone.PreferencesService
    {
        public abstract string name { get; }

        protected string service_name { get; private set; }
        private GLib.Settings settings;

        protected abstract async void handle_write_operation(string name, GLib.Variant value);

        protected void setup(string service_name)
        {
            this.service_name = service_name;
            this.settings = new GLib.Settings(service_name);
        }

        private async bool write(string name, GLib.Variant? value)
        {
            yield handle_write_operation(name, value);
            settings.set_value(name, value);
            return true;
        }

        private async GLib.Variant read(string name)
        {
            return settings.get_value(name);
        }

        public async void sync()
        {
            foreach (var key in settings.list_keys())
            {
                // simulate write operation so the service provider publishes the values
                // to it's dependencies
                var value = settings.get_value(key);
                assert( logger.debug(@"Read entry: $key = $(value.print(true))") );
                yield handle_write_operation(key, value);
            }
        }

        //
        // DBus API
        //

        public async string[] get_keys() throws DBusError, IOError
        {
            return settings.list_keys();
        }

        public async GLib.Variant get_value(string name) throws DBusError, IOError
        {
            var v = yield read(name);
            return v;
        }

        public async void set_value(string name, GLib.Variant value) throws DBusError, IOError
        {
            var result = yield write(name, value);
            // FIXME when write operation fails we need to throw an exception
        }

        public async bool is_profilable(string name) throws DBusError, IOError
        {
            return false;
        }

        public async string get_type_(string name) throws DBusError, IOError
        {
            var value = yield read(name);
            return value.get_type_string();
        }
    }
}
