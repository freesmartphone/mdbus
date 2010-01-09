/**
 * Copyright (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
 * Subsystem Interface
 *
 * A subsystem hosts a number of plugins that can expose service objects
 * via an IPC mechanism such as DBus.
 */
public interface FsoFramework.Subsystem : Object
{
    /**
     * Register plugins for this subsystem.
     * @return the number of registered plugins.
     **/
    public abstract uint registerPlugins();
    /**
     * Load registered plugins for this subsystem.
     * @return the number of loaded plugins.
     * Plugins are loaded in the order they appear in the register,
     * which in turn is the order they are defined in the configuration
     * file. You can use this to express dependencies.
     **/
    public abstract uint loadPlugins();
    /**
     * @return the name of this subsystem.
     **/
    public abstract string name();
    /**
     * @return plugin information.
     **/
    public abstract List<FsoFramework.PluginInfo?> pluginsInfo();
    /**
     * Claim a service name with the IPC mechanism.
     * @return true, if name could be claimed. false, otherwise.
     **/
    public abstract bool registerServiceName( string servicename );
    /**
     * Export an object via the IPC mechanims.
     * @return true, if object has been exported. false, otherwise.
     **/
    public abstract bool registerServiceObject( string servicename, string objectname, Object obj );
    /**
     * Shutdown the subsystem. This will call shutdown on all plugins.
     **/
    public abstract void shutdown();
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
        logger = Logger.createLogger( "libfsoframework", "subsystem" );
    }

    public uint registerPlugins()
    {
        assert ( _plugins == null ); // this method can only be called once
        _plugins = new List<FsoFramework.Plugin>();

        if ( !FsoFramework.SmartKeyFile.defaultKeyFile().hasSection( _name ) )
        {
            logger.warning( @"No section for $_name in configuration file. Not looking for plugins." );
            return 0;
        }
        if ( FsoFramework.SmartKeyFile.defaultKeyFile().boolValue( _name, "disabled", false ) )
        {
            logger.info( @"Subsystem $_name has been disabled in configuration file. Not looking for plugins." );
            return 0;
        }

        var names = FsoFramework.SmartKeyFile.defaultKeyFile().sectionsWithPrefix( _name + "." );
        var defaultpath = GLib.Path.build_filename( Config.PACKAGE_LIBDIR, "modules" );
        //FIXME: document plugin_path setting
        var pluginpath = FsoFramework.SmartKeyFile.defaultKeyFile().stringValue( "cornucopia", "plugin_path", defaultpath );

        assert( logger.debug( @"Pluginpath is $pluginpath" ) );

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

        assert( logger.debug( @"Registered $(_plugins.length()) plugins" ) );
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
                logger.warning( @"Could not load plugin: $(e.message)" );
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

    public void shutdown()
    {
        foreach ( var plugin in _plugins )
        {
            plugin.shutdown();
        }
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

/*
[DBus (name = "org.freesmartphone.DBus.Objects")]
public abstract interface DBusObjects
{
    public abstract void getNodes() throws DBus.Error;
}
*/

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
            assert( logger.debug( @"Connection for $servicename found; ok." ) );
            return true;
        }

        assert( logger.debug( @"Connection for $servicename not present yet; creating." ) );

        // get bus connection
        if ( _dbusconn == null )
        {
            try
            {
                _dbusconn = DBus.Bus.get( DBus.BusType.SYSTEM );
                _dbusobj = _dbusconn.get_object( DBus.DBUS_SERVICE_DBUS, DBus.DBUS_PATH_DBUS, DBus.DBUS_INTERFACE_DBUS );
            }
            catch ( DBus.Error e )
            {
                logger.critical( @"Could not get handle for DBus service object at system bus: $(e.message)" );
                return false;
            }
        }
        //uint res = _dbusobj.request_name( servicename, (uint) 0 );
        uint res = _dbusobj.RequestName( servicename, (uint) 0 );

        if ( res == DBus.RequestNameReply.PRIMARY_OWNER )
        {
            _dbusconnections.insert( servicename, _dbusconn );
            return true;
        }
        else
        {
            logger.critical( @"Can't acquire service name $servicename; service already running or not allowed in dbus configuration." );
            return false;
        }
    }

    public override bool registerServiceObject( string servicename, string objectname, Object obj )
    {
        var conn = _dbusconnections.lookup( servicename );
        if ( conn == null )
        {
            logger.warning( @"Can't register service object $objectname; service name $servicename could not be acquired." );
            return false;
        }

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
