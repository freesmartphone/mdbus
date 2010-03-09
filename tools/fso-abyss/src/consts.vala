/*
 * const.vala: constants and helper functions
 *
 * (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

namespace CONST
{
    //===========================================================================
    public const string DBUS_BUS_NAME  = "org.freedesktop.DBus";
    public const string DBUS_OBJ_PATH  = "/org/freedesktop/DBus";
    public const string DBUS_INTERFACE = "org.freedesktop.DBus";
    public const string DBUS_INTERFACE_INTROSPECTABLE = "org.freedesktop.DBus.Introspectable";

    public const string MUXER_BUS_NAME  = "org.freesmartphone.omuxerd";
    public const string MUXER_OBJ_PATH  = "/org/freesmartphone/GSM/Muxer";
    public const string MUXER_INTERFACE = "org.freesmartphone.GSM.MUX";
}
