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

FsoFramework.Logger logger;

/**
 * Subsystem
 */
public interface FsoFramework.Subsystem : Object
{
    public abstract void registerPlugins();
    public abstract uint loadPlugins();
    public abstract string name();
    public abstract List<FsoFramework.PluginInfo?> pluginsInfo();
}

/**
 * AbstractSubsystem
 */
public abstract class FsoFramework.AbstractSubsystem : FsoFramework.Subsystem, Object
{
    string _name;
    List<FsoFramework.Plugin> _plugins;

    public AbstractSubsystem( string name )
    {
        _name = name;
        logger = FsoFramework.createLogger( "subsystem" );
    }

    public void registerPlugins()
    {
        assert ( _plugins == null ); // this method can only be called once
        _plugins = new List<FsoFramework.Plugin>();

        if ( !FsoFramework.theMasterKeyFile().hasSection( _name ) )
        {
            logger.warning( "No section for %s in configuration file. Not looking for plugins.".printf( _name ) );
            return;
        }
        if ( FsoFramework.theMasterKeyFile().boolValue( _name, "disabled", false ) )
        {
            logger.info( "Subsystem %s has been disabled in configuration file. Not looking for plugins.".printf( _name ) );
            return;
        }

        var names = FsoFramework.theMasterKeyFile().sectionsWithPrefix( _name + "." );

        // FIXME: grab from build system
        var defaultpath = "/usr/local/lib/cornucopia/modules/%s/linux-gnu-i686".printf( _name );
        var pluginpath = FsoFramework.theMasterKeyFile().stringValue( "frameworkd", "plugin_path", defaultpath );

        logger.debug( "pluginpath is %s".printf( pluginpath ) );

        foreach ( var name in names )
        {
            var realname = name.replace( _name + ".", "" ); // cut subsystem name and dot
            string filename;
            if ( "%s" in pluginpath )
                filename = pluginpath.printf( realname );
            else
                filename = "%s/%s/%s".printf( pluginpath, _name, realname );
            var plugin = new FsoFramework.BasePlugin( filename );
            _plugins.append( plugin );
        }

        logger.debug( "registered %u plugins".printf( _plugins.length() ) );
    }

    public uint loadPlugins()
    {
        uint counter = 0;

        foreach ( var plugin in _plugins )
        {
            try
            {
                plugin.load();
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
