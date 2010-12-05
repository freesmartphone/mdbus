/**
 * Copyright (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 * Copyright (C) 2010 Denis 'GNUtoo' Carikli <GNUtoo@no-log.org>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 */

using GLib;
using FsoGsm;

extern int gpio_probe();
extern int gpio_enable();
extern int gpio_disable();
extern int gpio_remove();

class LowLevel.Nokia900 : FsoGsm.LowLevel, FsoFramework.AbstractObject
{
    public const string MODULE_NAME = "fsogsm.lowlevel_nokia900";
    private int err;

    construct
    {
		logger.info( "Registering nokia900 low level poweron/poweroff handling" );
		err = gpio_probe();
		if ( err != 0 )
			debug("lowlevel_nokia900_construct: error %d",err);
    }

    public override string repr()
    {
        return "<>";
    }

    public bool poweron()
    {
        debug( "lowlevel_nokia900_poweron()" );

        // always turn off first
        poweroff();
		err = gpio_enable();
		if (err != 0)
			debug("lowlevel_nokia900_poweron: gpio_enable error %d",err);
        return true;
    }

    public bool poweroff()
    {
        debug( "lowlevel_nokia900_poweroff()" );
		err = gpio_disable();
		if (err !=0 )
			debug("lowlevel_nokia900_poweroff: gpio_disable error %d",err);
        return true;
    }

    public bool suspend()
    {
        debug( "lowlevel_nokia900_suspend()" );
        return true;
    }

    public bool resume()
    {
        debug( "lowlevel_nokia900_resume()" );
        return true;
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
    FsoFramework.theLogger.debug( "lowlevel_nokia900 fso_factory_function" );
    return LowLevel.Nokia900.MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    // do not remove this function
}
