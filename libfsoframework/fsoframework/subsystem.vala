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

//triggers a bug in Vala
//const FsoFramework.Logger logger = FsoFramework.theMasterLogger( "subsystem" );

/**
 * Subsystem
 */
public interface FsoFramework.Subsystem : Object
{
    /*
    public abstract void setLevel( LogLevelFlags level );
    public abstract void setDestination( string destination );
    public abstract void debug( string message );
    public abstract void info( string message );
    public abstract void warning( string message );
    public abstract void error( string message );
    */
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
    }

    public void registerPlugins()
    {
        assert ( _plugins == null ); // this method can only be called once
        _plugins = new List<FsoFramework.Plugin>();
        var names = FsoFramework.theMasterKeyFile().sectionsWithPrefix( _name + "." );

        var pluginpath = FsoFramework.theMasterKeyFile().stringValue( "frameworkd", "plugin_path" );
        //logger.debug( "pluginpath is %s".printf( pluginpath ) );

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

        //logger.debug( "registered %d plugins".printf( _plugins.length() ) );
    }

    public void loadPlugins()
    {
        assert ( _plugins != null ); // need to call registerPlugins before loadPlugins
        foreach ( var plugin in _plugins )
        {
            plugin.load();
        }
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
