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
    private void toggle_modem_power_state()
    {
        if ( FsoFramework.FileHandling.isPresent( sysfs_modem_gpio ) )
        {
            assert( logger.debug( "Toggeling modem power state ..." ) );
            // 0,1,0 (duration: at least 200ms) toggles from on->off and from off->on
            Thread.usleep( 1000 * 100 );
            FsoFramework.FileHandling.write( "0\n", sysfs_modem_gpio );
            Thread.usleep( 1000 * 100 );
            FsoFramework.FileHandling.write( "1\n", sysfs_modem_gpio );
            Thread.usleep( 1000 * 100 );
            FsoFramework.FileHandling.write( "0\n", sysfs_modem_gpio );
        }
    }

    /**
     * Wait until the modem is powered on or off. This will probably block for some
     * seconds until the modem is powerd on or off.
     **/
    private bool wait_for_modem( bool powered )
    {
        int fd = -1;
        int count_retries = 5;

        assert( logger.debug( @"Waiting for modem to be in %s state ...".printf( powered ? "active" : "inactive" ) ) );

        do
        {
            fd = Posix.open( modem_application_node, Posix.O_RDWR );
            if ((powered && fd < 0) || (!powered && fd > 0))
            {
                assert( logger.debug( "Modem is not in %s state yet, waiting ...".printf( powered ? "active" : "inactive" ) ) );
                Posix.sleep( 1 );
            }
            count_retries--;
        }
        while ( ((powered && fd < 0 && Posix.errno == Posix.ENODEV) || (powered && fd > 0)) && count_retries >= 0 );

        return ( powered && FsoFramework.FileHandling.isPresent( modem_application_node ) ) ||
               ( !powered && !FsoFramework.FileHandling.isPresent( modem_application_node ) );
    }

    /**
     * Power on the modem. After calling this the modem is ready to use.
     * NOTE: Calling poweron() will probably block for some seconds until the
     * modem is completely initialized.
     **/
    public bool poweron()
    {
        // Power off the modem first. If modem is already off this does nothing.
        poweroff();

        toggle_modem_power_state();
        return wait_for_modem( false );
    }

    /**
     * Powering off the modem.
     * NOTE: Calling poweroff() will probably block for some seconds until the
     * modem is completely powered off.
     **/
    public bool poweroff()
    {
        // Be sure we're not already powered off
        if ( !is_powered() )
            return true;

        toggle_modem_power_state();
        return wait_for_modem( true );
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
