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
     * Register an object with the IPC mechanism.
     * If the service name is not claimed yet, attempt to claim it.
     **/
    public abstract void registerObjectForService<T>( string servicename, string objectpath, T obj );
    /**
     * Register an object with the IPC mechanism.
     * If the service name is not claimed yet, attempt to claim it.
     **/
    public abstract void registerObjectForServiceWithPrefix<T>( string servicename, string prefixpath, T obj );
    /**
     * Query registered plugins with a certain path prefix.
     **/
    public abstract Object[] allObjectsWithPrefix( string? prefix = null );
    /**
     * Shutdown the subsystem. This will call shutdown on all plugins.
     **/
    public abstract void shutdown();
    /**
     * Signal sent, when a servicename has been acquired.
     **/
    public signal void serviceNameAcquired( string servicename );
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
                //FIXME: Why do we not remove it here?
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

    public virtual void registerObjectForService<T>( string servicename, string objectpath, T obj )
    {
        assert_not_reached();
    }

    public virtual void registerObjectForServiceWithPrefix<T>( string servicename, string prefixpath, T obj )
    {
        assert_not_reached();
    }

    public virtual bool registerServiceObjectWithPrefix( string servicename, string prefix, Object obj )
    {
        assert_not_reached();
    }

    public virtual Object[] allObjectsWithPrefix( string? prefix = "null" )
    {
        assert_not_reached();
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
    public abstract void getNodes() throws DBusError;
}
*/

/**
 * DBusExportObject
 **/
public class FsoFramework.DBusExportObject
{
    public Object object;
    public int[] refids;
}

/**
 * DBusSubsystem
 */
public class FsoFramework.DBusSubsystem : FsoFramework.AbstractSubsystem
{
    DBusConnection connection;

    Gee.HashMap<string, Gee.ArrayList<uint>> refids;
    Gee.HashMap<string, Object> dbusobjects;
    Gee.HashMap<string, int> counters;
    Gee.HashSet<string> busnames;

    uint watch;

    public DBusSubsystem( string name )
    {
        base( name );
        refids = new Gee.HashMap<string, Gee.ArrayList<uint>>();
        dbusobjects = new Gee.HashMap<string, Object>();
        counters = new Gee.HashMap<string, int>();
        busnames = new Gee.HashSet<string>();
    }

    ~DBusSubsystem()
    {
        /*
        // FIXME: do we need to unregister the objects?
        foreach ( var name in dbusconnections )
        {
            uint res = dbusobj.ReleaseName( name );
        }
        */
    }

    private void ensureConnection()
    {
        if ( connection == null )
        {
            assert( logger.debug( @"Connection not present yet; creating." ) );
            try
            {
                connection = Bus.get_sync( BusType.SYSTEM );
            }
            catch ( Error e )
            {
                logger.critical( @"Could not connect to DBus System bus: $(e.message). dbus-daemon started?" );
                Posix.exit( -1 );
            }
            assert( connection != null );
        }
    }

    public void exportBusnames()
    {
        foreach ( var servicename in busnames )
        {
            // claim bus name
            Bus.own_name_on_connection( connection, servicename, 0,
            ( conn, name ) => {
                assert( logger.debug( @"Successfully claimed $name" ) );
                this.serviceNameAcquired( servicename ); /* SIGNAL */
            }, () => {
                logger.critical( @"Can't claim busname $servicename" );
                Posix.exit( -1 );
            } );
        }
    }

    public override void registerObjectForService<T>( string servicename, string objectpath, T obj )
    {
        ensureConnection();

        var cleanedname = objectpath.replace( "-", "_" ).replace( ":", "_" );
        try
        {
            var refid = connection.register_object<T>( cleanedname, obj );
            Gee.ArrayList<uint>? refidsForObject = refids[servicename];
            if ( refidsForObject == null )
            {
                refidsForObject = new Gee.ArrayList<uint>();
                refids[servicename] = refidsForObject;
            }
            refidsForObject.add( refid );
            dbusobjects[cleanedname] = (Object) obj;
        }
        catch ( Error e )
        {
            logger.error( @"Could not register $(typeof(T).name()) at $objectpath: $(e.message)" );
        }

        assert( logger.debug( @"Registered $(typeof(T).name()) at $objectpath" ) );

        busnames.add( servicename );

        if ( watch == 0 )
        {
            watch = Idle.add( () => {
                exportBusnames();
                return false; // mainloop: don't call again
            } );
        }
    }

    public override void registerObjectForServiceWithPrefix<T>( string servicename, string prefix, T obj )
    {
        var hash = @"$servicename:$prefix";
        int counter = counters[hash];
        registerObjectForService<T>( servicename, @"$prefix/$counter", obj );
        counters[hash] = ++counter;
    }

    public DBusConnection dbusConnection()
    {
        ensureConnection();
        return connection;
    }

    public override Object[] allObjectsWithPrefix( string? prefix = null )
    {
        var result = new Object[] {};
        foreach ( var objectname in dbusobjects.keys )
        {
            if ( prefix == null || objectname.has_prefix( prefix ) )
            {
                result += dbusobjects[objectname];
            }
        }
        return result;
    }
}

// vim:ts=4:sw=4:expandtab
