/*
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *                         Simon Busch <morphis@gravedo.de>
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

class LowLevel.PalmPre : FsoGsm.LowLevel, FsoFramework.AbstractObject
{
    public const string MODULE_NAME = "fsogsm.lowlevel_palmpre";
    private FsoGsm.AbstractModem modem; // for access to modem properties
    private string powernode;
    private string bootnode;
    private string wakeupnode;
    private bool powered_on;

    private const string DEFAULT_POWER_NODE  = "/sys/user_hw/pins/modem/power_on/level";
    private const string DEFAULT_BOOT_NODE   = "/sys/user_hw/pins/modem/boot_mode/level";
    private const string DEFAULT_WAKEUP_NODE = "/sys/user_hw/pins/modem/wakeup_modem/level";


    construct
    {
        modem = FsoGsm.theModem as FsoGsm.AbstractModem;
        powernode = config.stringValue( MODULE_NAME, "power_node", DEFAULT_POWER_NODE );
        bootnode = config.stringValue( MODULE_NAME, "boot_node", DEFAULT_BOOT_NODE );
        wakeupnode = config.stringValue( MODULE_NAME, "wakeup_node", DEFAULT_WAKEUP_NODE );

        powered_on = false;

        logger.info( "Registering Palm Pre low level poweron/poweroff handling" );
    }

    public override string repr()
    {
        return "<>";
    }

    public bool poweron()
    {
        debug( "lowlevel_palmpre_poweron()" );

        if ( powered_on )
        {
            // Power off first
            FsoFramework.FileHandling.write( "0", bootnode );
            FsoFramework.FileHandling.write( "0", wakeupnode );
            FsoFramework.FileHandling.write( "0", powernode );

            Posix.sleep(2);

            // Power on again
            FsoFramework.FileHandling.write( "1", powernode );
            FsoFramework.FileHandling.write( "1", wakeupnode );
        }
        else
        {
            FsoFramework.FileHandling.write( "1", powernode );
        }

        powered_on = true;

        return true;
    }

    public bool poweroff()
    {
        debug( "lowlevel_palmpre_poweroff()" );

        FsoFramework.FileHandling.write("0", bootnode);
        FsoFramework.FileHandling.write("0", powernode);

        powered_on = false;

        return true;
    }

    public bool suspend()
    {
        debug( "lowlevel_palmpre_suspend()" );
        return true;
    }

    public bool resume()
    {
        debug( "lowlevel_palmpre_resume()" );
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
    FsoFramework.theLogger.debug( "lowlevel_palmpre fso_factory_function" );
    return LowLevel.PalmPre.MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    // do not remove this function
}

// vim:ts=4:sw=4:expandtab
