/*
 * Copyright (C) 2012 Lukas 'Slyon' Märdian <lukasmaerdian@gmail.com>
 *               2012 Simon Busch <morphis@gravedo.de>
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
    private string modem_application_node;

    construct
    {
        sysfs_modem_gpio = config.stringValue( MODULE_NAME, "modem_toggle", "/sys/class/gpio/gpio186/value" );
        modem_application_node = config.stringValue( MODULE_NAME, "modem_application_node", "/dev/ttyHS_Application" );

        logger.info( "Registering gta04 low level modem toggle" );
    }

    public override string repr()
    {
        return "<>";
    }

    public bool is_powered()
    {
        return FsoFramework.FileHandling.isPresent( modem_application_node );
    }

    /*
     * Toggling the modem is needed since revision GTA04a4.
     * The GPIO node will not exist on GTA04a3, the modem is always powered there.
     */
    private bool toggle_modem_power_state( bool desired_power_state)
    {
        var retries = 0;

        var first_sleep = desired_power_state ? 200 : 100;
        var second_sleep = desired_power_state ? 100 : 200;

        if ( FsoFramework.FileHandling.isPresent( sysfs_modem_gpio ) )
        {
            while ( retries < 10 )
            {
                assert( logger.debug( "Trying to power modem %s ...".printf( desired_power_state ? "on" : "off" ) ) );

                // 0,1,0 (duration: at least 200ms) toggles from on->off and from off->on
                FsoFramework.FileHandling.write( "0\n", sysfs_modem_gpio );
                Thread.usleep( 1000 * first_sleep );
                FsoFramework.FileHandling.write( "1\n", sysfs_modem_gpio );
                Thread.usleep( 1000 * second_sleep );
                FsoFramework.FileHandling.write( "0\n", sysfs_modem_gpio );

                Posix.sleep( 3 );

                if ( ( desired_power_state && FsoFramework.FileHandling.isPresent( modem_application_node ) ) ||
                     ( !desired_power_state  && !FsoFramework.FileHandling.isPresent( modem_application_node ) ) )
                    break;

                retries++;
            }
        }
        else
        {
            assert( logger.debug( "Skipping modem power on/off sequence. Seems as we're on a GTA04A3." ) );
        }

        return retries < 5;
    }

    /**
     * Power on the modem. After calling this the modem is ready to use.
     * NOTE: Calling poweron() will probably block for some seconds until the
     * modem is completely initialized.
     **/
    public bool poweron()
    {
        if ( !poweroff() )
        {
            assert( logger.debug( @"Already active modem could not powered off!" ) );
            return false;
        }

        assert( logger.debug( @"Powering modem on now ..." ) );
        return toggle_modem_power_state( true );
    }

    /**
     * Powering off the modem.
     * NOTE: Calling poweroff() will probably block for some seconds until the
     * modem is completely powered off.
     **/
    public bool poweroff()
    {
        if ( !is_powered() )
        {
            assert( logger.debug( @"Skipping poweroff as modem is already not powered" ) );
            return true;
        }

        return toggle_modem_power_state( false );
    }

    /**
     * Suspend the modem - UNIMPLEMENTED
     **/
    public bool suspend()
    {
        return true;
    }

    /**
     * Resume the modem - UNIMPLEMENTED
     **/
    public bool resume()
    {
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
