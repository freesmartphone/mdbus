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
 * Errors
 */
public errordomain FsoFramework.PluginError
{
    UNABLE_TO_LOAD,
    FACTORY_NOT_FOUND,
}

/**
 * Delegates
 */
public delegate string FsoFramework.FactoryFunc();

/**
 * PluginInfo
 */
public struct FsoFramework.PluginInfo
{
    public string name;
    public bool loaded;
}

/**
 * Plugin
 */
public abstract interface FsoFramework.Plugin : Object
{
    public abstract void load() throws FsoFramework.PluginError;
    public abstract FsoFramework.PluginInfo info();
}

/**
 * BasePlugin
 */
public class FsoFramework.BasePlugin : FsoFramework.Plugin, Object
{
    string filename;
    FsoFramework.PluginInfo pluginInfo;
    Module module;

    public BasePlugin( string filename )
    {
        this.filename = "%s.%s".printf( filename, Module.SUFFIX );
        pluginInfo = FsoFramework.PluginInfo() { name=null, loaded=false };
    }

    public void load() throws FsoFramework.PluginError
    {
        // try to load it
        module = Module.open( filename, 0 );
        if ( module == null )
            throw new FsoFramework.PluginError.UNABLE_TO_LOAD( "could not load %s: %s".printf( filename, Module.error() ) );

        // try to resolve factory method
        void* func;
        var ok = module.symbol( "fso_factory_function", out func );
        if ( !ok )
            throw new FsoFramework.PluginError.FACTORY_NOT_FOUND( "could not find symbol: %s".printf( Module.error() ) );

        // call factory method to acquire name
        FsoFramework.FactoryFunc fso_factory_function = (FsoFramework.FactoryFunc) func;
        pluginInfo.name = fso_factory_function();

        pluginInfo.loaded = true;
    }

    public PluginInfo info()
    {
        return pluginInfo;
    }
}

