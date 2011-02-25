/*
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

namespace DBusService
{
    public const string DBUS_SERVICE_DBUS             = "org.freedesktop.DBus";
    public const string DBUS_PATH_DBUS                = "/org/freedesktop/DBus";

    public const string DBUS_INTERFACE_INTROSPECTABLE = "org.freedesktop.DBus.Introspectable";
    public const string DBUS_INTERFACE_PROPERTIES     = "org.freedesktop.DBus.Properties";
    public const string DBUS_INTERFACE_PEER           = "org.freedesktop.DBus.Peer";
    public const string DBUS_INTERFACE_DBUS           = "org.freedesktop.DBus";

    [DBus (name = "org.freedesktop.DBus.Introspectable")]
    public interface IIntrospectable : GLib.Object
    {
        public abstract async string Introspect () throws DBusError, IOError;
    }

    [DBus (name = "org.freedesktop.DBus.Properties")]
    public interface IProperties : GLib.Object
    {
        public abstract async GLib.Variant                   Get (string iface, string prop) throws DBusError, IOError;
        public abstract async void                           Set (string iface, string prop, Variant val) throws DBusError, IOError;
        public abstract async GLib.HashTable<string,Variant> GetAll (string iface) throws DBusError, IOError;
    }

    [DBus (name = "org.freedesktop.DBus.Peer")]
    public interface IPeer : GLib.Object
    {
        public abstract async void Ping () throws DBusError, IOError;
    }

    [DBus (name = "org.freedesktop.DBus")]
    public interface IDBus : GLib.Object
    {
        public abstract async void     AddMatch( string match ) throws DBusError, IOError;
        public abstract async uint8[]  GetAdtAuditSessionData( string type ) throws DBusError, IOError;
        public abstract async uint8[]  GetConnectionSELinuxSecurityContext( string type ) throws DBusError, IOError;
        public abstract async uint32   GetConnectionUnixProcessID( string conn ) throws DBusError, IOError;
        public abstract async uint32   GetConnectionUnixUser( string conn ) throws DBusError, IOError;
        public abstract async string   GetId() throws DBusError, IOError;
        public abstract async string   GetNameOwner( string name ) throws DBusError, IOError;
        public abstract async string   Hello() throws DBusError, IOError;
        public abstract async string[] ListActivatableNames() throws DBusError, IOError;
        public abstract async string[] ListNames() throws DBusError, IOError;
        public abstract async string[] ListQueuedOwners( string None ) throws DBusError, IOError;
        public abstract async bool     NameHasOwner( string name ) throws DBusError, IOError;
        public abstract async uint32   ReleaseName( string name ) throws DBusError, IOError;
        public abstract async void     ReloadConfig() throws DBusError, IOError;
        public abstract async void     RemoveMatch( string match ) throws DBusError, IOError;
        public abstract async uint32   RequestName( string name, uint32 flags ) throws DBusError, IOError;
        public abstract async uint32   StartServiceByName( string name, uint32 flags ) throws DBusError, IOError;
        public abstract async void     UpdateActivationEnvironment( GLib.HashTable<string,string> environment ) throws DBusError, IOError;

        public signal void             NameAcquired( string name );
        public signal void             NameLost( string name );
        public signal void             NameOwnerChanged( string name, string oldowner, string newowner );
    }

    [DBus (name = "org.freedesktop.DBus")]
    public interface IDBusSync : GLib.Object
    {
        public abstract void           AddMatch( string match ) throws DBusError, IOError;
        public abstract uint8[]        GetAdtAuditSessionData( string type ) throws DBusError, IOError;
        public abstract uint8[]        GetConnectionSELinuxSecurityContext( string type ) throws DBusError, IOError;
        public abstract uint32         GetConnectionUnixProcessID( string conn ) throws DBusError, IOError;
        public abstract uint32         GetConnectionUnixUser( string conn ) throws DBusError, IOError;
        public abstract string         GetId() throws DBusError, IOError;
        public abstract string         GetNameOwner( string name ) throws DBusError, IOError;
        public abstract string         Hello() throws DBusError, IOError;
        public abstract string[]       ListActivatableNames() throws DBusError, IOError;
        public abstract string[]       ListNames() throws DBusError, IOError;
        public abstract string[]       ListQueuedOwners( string None ) throws DBusError, IOError;
        public abstract bool           NameHasOwner( string name ) throws DBusError, IOError;
        public abstract uint32         ReleaseName( string name ) throws DBusError, IOError;
        public abstract void           ReloadConfig() throws DBusError, IOError;
        public abstract void           RemoveMatch( string match ) throws DBusError, IOError;
        public abstract uint32         RequestName( string name, uint32 flags ) throws DBusError, IOError;
        public abstract uint32         StartServiceByName( string name, uint32 flags ) throws DBusError, IOError;
        public abstract void           UpdateActivationEnvironment( GLib.HashTable<string,string> environment ) throws DBusError, IOError;

        public signal void             NameAcquired( string name );
        public signal void             NameLost( string name );
        public signal void             NameOwnerChanged( string name, string oldowner, string newowner );
    }
}

// misc helper classes and functions

namespace FsoFramework {

public bool isValidDBusName( string busname )
{
    var parts = busname.split( "." );
    if ( parts.length < 2 )
    {
        return false;
    }
    if ( busname.has_prefix( "." ) )
    {
        return false;
    }
    if ( busname.has_suffix( "." ) )
    {
        return false;
    }
    return true;
}

} /* namespace FsoFramework */

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

#if 0
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
    private dynamic Object obj;

    private HashTable<string, List<DBusFuncDelegateHolder>> appear;
    private HashTable<string, List<DBusFuncDelegateHolder>> disappear;

    public DBusServiceNotifier()
    {
        appear = new HashTable<string,List<DBusFuncDelegateHolder>>( str_hash, str_equal );
        disappear = new HashTable<string,List<DBusFuncDelegateHolder>>( str_hash, str_equal );

        assert_not_reached();

        try
        {
            obj = Bus.get_proxy_sync<DBusService.IDBus>( BusType.SYSTEM, DBusService.DBUS_SERVICE_DBUS, DBusService.DBUS_PATH_DBUS );
        }
        catch ( DBusError e )
        {
            logger.critical( @"Could not get handle on DBus object at system bus: $(e.message)" );
        }
        catch ( IOError e )
        {
            logger.critical( @"Could not get handle on DBus object at system bus: $(e.message)" );
        }
        obj.NameOwnerChanged.connect( onNameOwnerChanged );
    }

    public override string repr()
    {
        return "";
    }

    private void onNameOwnerChanged( dynamic Object obj, string name, string oldowner, string newowner )
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
#endif
