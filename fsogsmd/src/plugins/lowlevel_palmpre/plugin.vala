/**
 * Copyright (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

class LowLevel.PalmPre : FsoGsm.LowLevel, FsoFramework.AbstractObject
{
    public const string MODULE_NAME = "fsogsm.lowlevel_palmpre";
    private string powerOnNode;
    private string wakeupModemNode;
    private string bootModeNode;
    private FsoGsm.AbstractModem modem; // for access to modem properties

    construct
    {
        // power node
        powerOnNode = config.stringValue( MODULE_NAME, "power_on_node", "unknown" );
        wakeupModemNode = config.stringValue( MODULE_NAME, "wakeup_modem_node", "unknown" );
        bootModeNode = config.stringValue( MODULE_NAME, "boot_mode_node", "unknown" );
        
        // modem
        modem = FsoGsm.theModem as FsoGsm.AbstractModem;

        logger.info( "Registering palmpre low level poweron/poweroff handling" );
    }

    public override string repr()
    {
        return "<>";
    }

    public bool poweron()
    {
        debug( "lowlevel_palmpre_poweron()" );

        if ( powerOnNode == "unknown" )
        {
            logger.error( "power_node not defined. Can't poweron." );
            return false;
        }

        // always turn off first
        poweroff();
        FsoFramework.FileHandling.write( "0\n", wakeupModemNode );

        Thread.usleep( 1000 * 2000 );

        FsoFramework.FileHandling.write( "1\n", powerOnNode );
        FsoFramework.FileHandling.write( "1\n", wakeupModemNode );
        
        return true;
    }

    public bool poweroff()
    {
        debug( "lowlevel_palmpre_poweroff()" );
        FsoFramework.FileHandling.write( "0\n", powerOnNode );
        FsoFramework.FileHandling.write( "0\n", bootModeNode );
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
