/*
 * (C) 2011 Simon Busch <morphis@gravedo.de>
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

namespace FsoTest
{
    public class TestResult : GLib.Object
    {
        public string test_name { get; private set; }
        public bool success { get; private set; }
        public string message { get; private set; }

        public TestResult( string test_name, bool success, string message = "" )
        {
            this.test_name = test_name;
            this.success = success;
            this.message = message;
        }
    }
}

// vim:ts=4:sw=4:expandtab
