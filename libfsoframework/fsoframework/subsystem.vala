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

/**
 * Subsystem
 */
public interface FsoFramework.Subsystem : Object
{
    public abstract uint registerPlugins();
    public abstract uint loadPlugins();
    public abstract string name();
    public abstract List<FsoFramework.PluginInfo?> pluginsInfo();

    public abstract bool registerServiceName( string servicename );
    public abstract bool registerServiceObject( string servicename, string objectname, Object obj );
}

/**
 * AbstractSubsystem
 */
public abstract class FsoFramework.AbstractSubsystem : FsoFramework.Subsystem, Object
{
    protected FsoFramework.Logger logger;
    string _name;
    List<FsoFramework.Plugin> _plugins;

    public AbstractSubsystem( string name )
    {
        _name = name;
        logger = FsoFramework.createLogger( "subsystem" );
    }

    public uint registerPlugins()
    {
        assert ( _plugins == null ); // this method can only be called once
        _plugins = new List<FsoFramework.Plugin>();

        if ( !FsoFramework.theMasterKeyFile().hasSection( _name ) )
        {
            logger.warning( "No section for %s in configuration file. Not looking for plugins.".printf( _name ) );
            return 0;
        }
        if ( FsoFramework.theMasterKeyFile().boolValue( _name, "disabled", false ) )
        {
            logger.info( "Subsystem %s has been disabled in configuration file. Not looking for plugins.".printf( _name ) );
            return 0;
        }

        var names = FsoFramework.theMasterKeyFile().sectionsWithPrefix( _name + "." );

        var defaultpath = "%s/lib/cornucopia/modules".printf( getPrefixForExecutable() );
        var pluginpath = FsoFramework.theMasterKeyFile().stringValue( "cornucopia", "plugin_path", defaultpath );

        logger.debug( "pluginpath is %s".printf( pluginpath ) );

        foreach ( var name in names )
        {
            var realname = name.replace( _name + ".", "" ); // cut subsystem name and dot
            string filename;
            if ( "./.libs" in pluginpath )
                filename = pluginpath.printf( realname );
            else
                filename = "%s/%s/%s".printf( pluginpath, _name, realname );
            var plugin = new FsoFramework.BasePlugin( filename, this );
            _plugins.append( plugin );
        }

        logger.debug( "registered %u plugins".printf( _plugins.length() ) );
        return _plugins.length();
    }

    public uint loadPlugins()
    {
        uint counter = 0;

        foreach ( var plugin in _plugins )
        {
            try
            {
                plugin.loadAndInit();
                counter++;
            }
            catch ( FsoFramework.PluginError e )
            {
                logger.warning( "could not load plugin: %s".printf( e.message ) );
            }
        }
        return counter;
    }

    public string name()
    {
        return _name;
    }

    public List<FsoFramework.PluginInfo?> pluginsInfo()
    {
        var list = new List<FsoFramework.PluginInfo?>();
        foreach ( var plugin in _plugins )
        {
            list.append( plugin.info() );
        }
        return list;
    }

    public virtual bool registerServiceName( string servicename )
    {
        return false;
    }

    public virtual bool registerServiceObject( string servicename, string objectname, Object obj )
    {
        return false;
    }
}

/**
 * BaseSubsystem
 */
public class FsoFramework.BaseSubsystem : FsoFramework.AbstractSubsystem
{
    public BaseSubsystem( string name )
    {
        base( name );
    }
}

/**
 * Subsystem query interface
 */
[DBus (name = "org.freesmartphone.DBus.Objects")]
public abstract interface DBusObjects
{
    public abstract void getNodes() throws DBus.Error;
}

/**
 * DBusSubsystem
 */
public class FsoFramework.DBusSubsystem : FsoFramework.AbstractSubsystem
{
    DBus.Connection _dbusconn;
    dynamic DBus.Object _dbusobj;

    HashTable<string, DBus.Connection> _dbusconnections;
    HashTable<string, Object> _dbusobjects;

    public DBusSubsystem( string name )
    {
        base( name );
        _dbusconnections = new HashTable<string, DBus.Connection>( str_hash, str_equal );
        _dbusobjects = new HashTable<string, Object>( str_hash, str_equal );
    }

    ~DBusSubsystem()
    {
        // FIXME: do we need to unregister the objects?
        foreach ( var name in _dbusconnections.get_keys() )
        {
            uint res = _dbusobj.release_name( name );
        }
    }

    public override bool registerServiceName( string servicename )
    {
        var connection = _dbusconnections.lookup( servicename );
        if ( connection != null )
        {
            logger.debug( "connection for '%s' found; ok.".printf( servicename ) );
            return true;
        }

        logger.debug( "connection for '%s' not present yet; creating.".printf( servicename ) );

        // get bus connection
        if ( _dbusconn == null )
        {
            _dbusconn = DBus.Bus.get( DBus.BusType.SYSTEM );
            _dbusobj = _dbusconn.get_object( DBUS_BUS_NAME, DBUS_BUS_PATH, DBUS_BUS_INTERFACE );
        }
        assert ( _dbusconn != null );
        assert ( _dbusobj != null );

        uint res = _dbusobj.request_name( servicename, (uint) 0 );
        if ( res == DBus.RequestNameReply.PRIMARY_OWNER )
        {
            _dbusconnections.insert( servicename, _dbusconn );
            return true;
        }
        else
        {
            logger.warning( "can't request request dbus service name '%s'; service already running or not allowed in dbus configuration.".printf( servicename ) );
            return false;
        }
    }

    public override bool registerServiceObject( string servicename, string objectname, Object obj )
    {
        var conn = _dbusconnections.lookup( servicename );
        assert ( conn != null );

        // clean objectname
        var cleanedname = objectname.replace( "-", "_" ).replace( ":", "_" );

        conn.register_object( cleanedname, obj );
        _dbusobjects.insert( cleanedname, obj );
        return true;
    }

    public DBus.Connection dbusConnection()
    {
        assert( _dbusconn != null );
        return _dbusconn;
    }

}
