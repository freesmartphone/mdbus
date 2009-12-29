/**
 * Copyright (C) 2009 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

using GLib;

namespace FsoFramework {

internal static DBusServiceNotifier _dbusservicenotifier = null;

/**
 * @returns @a Logger configured as requested in frameworkd.conf
 **/
public static Logger createLogger( string group, string domain )
{
    warning( "FsoFramework.createLogger is DEPRECATED, please use Logger.createLogger" );
    return Logger.createLogger( group, domain );
}

/**
 * @returns @a DBusServiceNotifier
 **/
public static DBusServiceNotifier theDBusServiceNotifier()
{
    if ( _dbusservicenotifier == null )
    {
        _dbusservicenotifier = new DBusServiceNotifier();
    }
    return _dbusservicenotifier;
}


} /* namespace */
