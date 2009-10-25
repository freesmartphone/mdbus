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

// inject useful constants into namespace until they are in dbus-glib-1.vapi
namespace DBus
{
    public const string DBUS_SERVICE_DBUS             = "org.freedesktop.DBus";
    public const string DBUS_PATH_DBUS                = "/org/freedesktop/DBus";
    public const string DBUS_INTERFACE_DBUS           = "org.freedesktop.DBus";

    public const string DBUS_INTERFACE_INTROSPECTABLE = "org.freedesktop.DBus.Introspectable";
    public const string DBUS_INTERFACE_PROPERTIES     = "org.freedesktop.DBus.Properties";
    public const string DBUS_INTERFACE_PEER           = "org.freedesktop.DBus.Peer";
}

public delegate void FsoFramework.DBusServiceEventFunc( string busname );

[Compact]
internal class DBusFuncDelegateHolder
{
    public FsoFramework.DBusServiceEventFunc func;
    public DBusFuncDelegateHolder( FsoFramework.DBusServiceEventFunc func )
    {
        this.func = func;
    }
}

/**
 * @class FsoFramework.DBusServiceNotifierDelegate
 */
internal class FsoFramework.DBusServiceNotifierDelegate<T>
{
    private T t;

    public DBusServiceNotifierDelegate( owned T t )
    {
        this.t = t;
    }
}

/**
 * @class FsoFramework.DBusServiceNotifier
 *
 **/
public class FsoFramework.DBusServiceNotifier : FsoFramework.AbstractObject
{
    private dynamic DBus.Object obj;

    private HashTable<string, List<DBusFuncDelegateHolder>> appear;
    private HashTable<string, List<DBusFuncDelegateHolder>> disappear;

    public DBusServiceNotifier()
    {
        appear = new HashTable<string,List<DBusFuncDelegateHolder>>( str_hash, str_equal );
        disappear = new HashTable<string,List<DBusFuncDelegateHolder>>( str_hash, str_equal );

        try
        {
            obj = DBus.Bus.get( DBus.BusType.SYSTEM ).get_object( DBus.DBUS_SERVICE_DBUS, DBus.DBUS_PATH_DBUS, DBus.DBUS_INTERFACE_DBUS );
        }
        catch ( DBus.Error e )
        {
            logger.critical( @"Could not get handle on DBus object at system bus: $(e.message)" );
        }
        obj.NameOwnerChanged += onNameOwnerChanged;
    }

    public override string repr()
    {
        return "";
    }

    private void onNameOwnerChanged( dynamic DBus.Object obj, string name, string oldowner, string newowner )
    {
        weak List<weak DBusFuncDelegateHolder> list;

        // check for service appearing
        if ( oldowner == "" && newowner != "" )
            list = appear.lookup( name );
        else if ( oldowner != "" && newowner == "" )
            list = disappear.lookup( name );
        else
            return;

        if ( list != null )
        {
            foreach ( var el in list )
            {
                el.func( name );
            }
        }
    }

    public void notifyAppearing( string busname, DBusServiceEventFunc callback )
    {
        weak List<DBusFuncDelegateHolder> list = appear.lookup( busname );
        if ( list == null )
        {
            var newlist = new List<DBusFuncDelegateHolder>();
            newlist.append( new DBusFuncDelegateHolder( callback ) );
            appear.insert( busname, (owned) newlist );
        }
        else
        {
        list.append( new DBusFuncDelegateHolder( callback ) );
        }
    }

    public void notifyDisappearing( string busname, DBusServiceEventFunc callback )
    {
        weak List<DBusFuncDelegateHolder> list = disappear.lookup( busname );
        if ( list == null )
        {
            var newlist = new List<DBusFuncDelegateHolder>();
            newlist.append( new DBusFuncDelegateHolder( callback ) );
            disappear.insert( busname, (owned) newlist );
        }
        else
        {
            list.append( new DBusFuncDelegateHolder( callback ) );
        }
    }

}
