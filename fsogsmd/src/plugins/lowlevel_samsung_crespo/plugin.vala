/*
 * Copyright (C) 2011 Simon Busch <morphis@gravedo.de>
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
using FsoFramework;

class LowLevel.SamsungCrespo : FsoGsm.LowLevel, FsoFramework.AbstractObject
{
    public const string MODULE_NAME = "fsogsm.lowlevel_samsung_crespo";

    private FsoGsm.AbstractModem modem; // for access to modem properties
    private SamsungIpc.Client client;
    private bool powered = false;
    private string power_mode_node;

    construct
    {
        modem = FsoGsm.theModem as FsoGsm.AbstractModem;
        client = new SamsungIpc.Client(SamsungIpc.ClientType.CRESPO_FMT);

        power_mode_node = config.stringValue( MODULE_NAME, "power_mode_node", "/sys/devices/platform/modemctl/power_mode" );

        logger.info( "Registering Samsung Crespo low level poweron/poweroff handling" );
    }

    public override string repr()
    {
        return "<>";
    }

    public bool poweron()
    {
        assert( logger.debug( "lowlevel_samsung_crespo_poweron()" ) );

        if ( powered )
            return false;

        if (client.bootstrap_modem() != 0)
        {
            logger.error( "Modem bootstraping went wrong; cannot power the modem!" );
            return false;
        }

        FsoFramework.FileHandling.write( "1", power_mode_node );

        Posix.sleep( 1 );

        return true;
    }

    public bool poweroff()
    {
        assert( logger.debug( "lowlevel_samsung_crespo_poweroff()" ) );

        if ( !powered )
            return false;

        FsoFramework.FileHandling.write( "0", power_mode_node );

        return true;
    }

    public bool suspend()
    {
        assert( logger.debug( "lowlevel_samsung_crespo_suspend()" ) );
        return true;
    }

    public bool resume()
    {
        assert( logger.debug( "lowlevel_samsung_crespo_resume()" ) );
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
    FsoFramework.theLogger.debug( "lowlevel_samsung_crespo fso_factory_function" );
    return LowLevel.SamsungCrespo.MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    // do not remove this function
}

// vim:ts=4:sw=4:expandtab
