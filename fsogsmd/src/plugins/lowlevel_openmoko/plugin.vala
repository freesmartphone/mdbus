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

using FsoGsm;

class LowLevel.Openmoko : FsoGsm.LowLevel, FsoFramework.AbstractObject
{
    construct
    {
        logger.info( "Registering openmoko low level poweron/poweroff handling" );
    }

    public override string repr()
    {
        return "<>";
    }

    public bool poweron()
    {
        return false;
    }

    public bool poweroff()
    {
        return false;
    }
}

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    debug( "lowlevel_openmoko fso_factory_function" );
    return "fsogsmd.lowlevel_openmoko";
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    // do not remove this function
}
