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
        var names = theMasterKeyFile().sectionsWithPrefix( _name );
        foreach ( var name in names )
        {
/*            var filename = "%s/%s/%s".printf();
            plugin = FsoFramework.Plugin(*/
        }
    }

    public string name()
    {
        return _name;
    }
}

