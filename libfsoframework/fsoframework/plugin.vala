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
    REGISTER_NOT_FOUND,
    FACTORY_NOT_FOUND,
    UNABLE_TO_INITIALIZE,
}

/**
 * Delegates
 */
public static delegate string FsoFramework.FactoryFunc( FsoFramework.Subsystem subsystem ) throws Error;
public static delegate void FsoFramework.RegisterFunc( TypeModule bar );

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
    public abstract void loadAndInit() throws FsoFramework.PluginError;
    public abstract PluginInfo info();
}

/**
 * BasePlugin
 */
public class FsoFramework.BasePlugin : FsoFramework.Plugin, TypeModule
{
    string filename;
    Module module;
    FsoFramework.PluginInfo pluginInfo;
    FsoFramework.Subsystem subsystem;

    public BasePlugin( string filename, FsoFramework.Subsystem subsystem )
    {
        this.filename = "%s.%s".printf( filename, Module.SUFFIX );
        this.subsystem = subsystem;
        pluginInfo = FsoFramework.PluginInfo() { name=null, loaded=false };

        // FIXME: bump ref so it doesn't get disposed. This works around a bug in
        // Vala -- removing an unsolicitated call to g_object_dispose in TypeModule.
        this.ref();
    }

    public void loadAndInit() throws FsoFramework.PluginError
    {
        // try to load it
        module = Module.open( filename, ModuleFlags.BIND_LAZY | ModuleFlags.BIND_LOCAL );
        if ( module == null )
            throw new FsoFramework.PluginError.UNABLE_TO_LOAD( "could not load %s: %s".printf( filename, Module.error() ) );

        // try to resolve register method
        void* regfunc;
        var ok = module.symbol( "fso_register_function", out regfunc );

        if ( !ok )
            throw new FsoFramework.PluginError.REGISTER_NOT_FOUND( "could not find symbol: %s".printf( Module.error() ) );

        FsoFramework.RegisterFunc fso_register_function = (FsoFramework.RegisterFunc) regfunc;
        fso_register_function( this );

        // try to resolve factory method
        void* loadfunc;
        ok = module.symbol( "fso_factory_function", out loadfunc );
        if ( !ok )
            throw new FsoFramework.PluginError.FACTORY_NOT_FOUND( "could not find symbol: %s".printf( Module.error() ) );

        FactoryFunc fso_factory_func = (FactoryFunc) loadfunc;

        try
        {
            // call factory method to acquire name
            pluginInfo.name = fso_factory_func( subsystem );
            // flag as loaded
            pluginInfo.loaded = true;
        }
        catch ( Error e )
        {
            module = null;
            throw new FsoFramework.PluginError.UNABLE_TO_INITIALIZE( "factory function error: %s".printf( e.message ) );
        }
    }

    public PluginInfo info()
    {
        return pluginInfo;
    }

    public override bool load()
    {
        message( "%s load (GType is in use)", filename );
        return true;
    }

    public override void unload()
    {
        message( "%s unload (GType is no longer in use)", filename );
    }

}

