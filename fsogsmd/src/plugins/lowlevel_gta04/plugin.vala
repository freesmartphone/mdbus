/*
 * Copyright (C) 2012 Lukas 'Slyon' Märdian <lukasmaerdian@gmail.com>
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

class LowLevel.GTA04 : FsoGsm.LowLevel, FsoFramework.AbstractObject
{
    public const string MODULE_NAME = "fsogsm.lowlevel_gta04";
    private string sysfs_modem_gpio;

    construct
    {
        sysfs_modem_gpio = config.stringValue( MODULE_NAME, "modem_toggle", "/sys/class/gpio/gpio186/value" );

        logger.info( "Registering gta04 low level modem toggle" );
    }

    public override string repr()
    {
        return "<>";
    }

    /*
     * Toggling the modem is needed since revision GTA04a4.
     * The GPIO node will not exist on GTA04a3, the modem is always powered there.
     */
    public bool toggle()
    {
#if DEBUG
        debug( "lowlevel_gta04_toggle()" );
#endif
        //TODO: check if the modem is powered on or off, e.g. via lsusb:
        //      Bus 001 Device 002: ID 0af0:8800 Option

        if ( FsoFramework.FileHandling.isPresent( sysfs_modem_gpio ) )
        {
            // 0,1,0 (duration: at least 200ms) toggles from on->off and from off->on
            Thread.usleep( 1000 * 100 );
            FsoFramework.FileHandling.write( "0\n", sysfs_modem_gpio );
            Thread.usleep( 1000 * 100 );
            FsoFramework.FileHandling.write( "1\n", sysfs_modem_gpio );
            Thread.usleep( 1000 * 100 );
            FsoFramework.FileHandling.write( "0\n", sysfs_modem_gpio );
        }

        // we need to sleep for at least 1 - 2 seconds until the relevant devices are
        // created by udev/devtmpfs. As the whole poweron logic is synchronous, we have no
        // other option as forcing a sleep time for the whole daemon.
        Posix.sleep( 2 );

        return true;
    }

    public bool poweron()
    {
#if DEBUG
        debug( "lowlevel_gta04_poweron()" );
#endif
        bool ret = toggle();
        return ret;
    }

    public bool poweroff()
    {
#if DEBUG
        debug( "lowlevel_gta04_poweroff()" );
#endif
        return true;
    }

    public bool suspend()
    {
#if DEBUG
        debug( "lowlevel_gta04_suspend()" );
#endif
        return true;
    }

    public bool resume()
    {
#if DEBUG
        debug( "lowlevel_gta04_resume()" );
#endif
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
    FsoFramework.theLogger.debug( "lowlevel_gta04 fso_factory_function" );
    return LowLevel.GTA04.MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    // do not remove this function
}

// vim:ts=4:sw=4:expandtab
