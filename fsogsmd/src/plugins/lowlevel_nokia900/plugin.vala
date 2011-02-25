/**
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 * Copyright (C) 2010 Denis 'GNUtoo' Carikli <GNUtoo@no-log.org>
 *                    Klaus 'mrmoku' Kurzmann <mok@fluxnetz.de>
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


class LowLevel.Nokia900 : FsoGsm.LowLevel, FsoFramework.AbstractObject
{
    public enum RapuType
    {
        TYPE_1,
        TYPE_2
    }

    public const string MODULE_NAME = "fsogsm.lowlevel_nokia900";

    private const string GPIO_SWITCH = "/sys/devices/platform/gpio-switch";
    private const string DEV_CMT = "/dev/cmt";
    private const string GPIO_DIR = "/sys/class/gpio";

    private const int cmt_en = 0;
    private const int cmt_rst_rq = 1;
    private const int cmt_rst = 2;
    private const int cmt_bsi = 3;
    private const int cmt_apeslpx = 4;

    private RapuType rapu_type;

    private bool reset_in_progress;
    private bool startup_in_progress;

    private bool have_gpio_switch;
    private bool have_gpio[5];


    construct
    {
        logger.info( "Registering nokia900 low level poweron/poweroff handling" );
		gpio_probe();
    }

    private string gpio_idx2string( int idx )
    {
        switch ( idx )
        {
            case cmt_en:
                return "cmt_en";
            case cmt_rst_rq:
                return "cmt_rst_rq";
            case cmt_rst:
                return "cmt_rst";
            case cmt_bsi:
                return "cmt_bsi";
            case cmt_apeslpx:
                return "cmt_apeslpx";
        }

        return "";
    }

    private string filename_for_gpio_line( int line )
    {
        if ( have_gpio_switch )
            return @"$GPIO_SWITCH/$(gpio_idx2string( line ))/state";

        return @"$DEV_CMT/$(gpio_idx2string( line ))/value";
    }

    private string value_to_gpio_string( bool value )
    {
        if ( have_gpio_switch )
            return value ? "active" : "inactive";

        return value ? "1" : "0";
    }


    private void gpio_write( int line, bool value )
    {
        if ( !have_gpio[line] )
        {
            assert( logger.debug( @"gpio_write: we don't have gpio $(gpio_idx2string( line )) - ignoring" ) );
            return;
        }

        assert( logger.debug( @"gpio_write: writing $( value_to_gpio_string( value )) to $( filename_for_gpio_line( line ))" ) );
        FsoFramework.FileHandling.write( value_to_gpio_string( value ), filename_for_gpio_line( line ) );
    }

    private bool gpio_line_probe( int line )
    {
        assert( logger.debug( @"probing for $(filename_for_gpio_line( line ))" ) );
        return FsoFramework.FileHandling.isPresent( filename_for_gpio_line( line ) );
    }

    private bool gpio_probe_links()
    {
        /* we can't create the links in DEV_CMT as current kernels
         * lack the name property in /sys/class/gpio/gpioXYZ
         * only thing we can do is check if DEV_CMT is there
         * and hope the links in there are already set up */
        return FsoFramework.FileHandling.isPresent( DEV_CMT );
    }

    private void gpio_probe()
    {
        have_gpio_switch = FsoFramework.FileHandling.isPresent( GPIO_SWITCH );

        if ( have_gpio_switch )
            logger.info( @"Using $GPIO_SWITCH switch" );
        else
        {
            if ( !gpio_probe_links() )
                return;
            logger.info( @"Using $DEV_CMT" );
        }

        /* GPIO lines availability depends on HW and SW versions */
        for ( int f = 0; f < 5; f++ )
        {
            have_gpio[f] = gpio_line_probe( f );
            assert( logger.debug( @"   --> $(gpio_idx2string( f )): $(have_gpio[f])" ) );
        }

        if ( !have_gpio[cmt_en] )
        {
            logger.warning( "Modem control GPIO lines are not available" );
            return;
        }

        if ( have_gpio[cmt_bsi] )
            rapu_type = RapuType.TYPE_1;
        else
            rapu_type = RapuType.TYPE_2;

        assert( logger.debug( @"gpio_probe: rapu is $rapu_type" ) );
    }


    public override string repr()
    {
        return "<>";
    }

    public bool poweron()
    {
        assert( logger.debug( "lowlevel_nokia900_poweron()" ) );

        // always turn off first
        poweroff();

        gpio_write( cmt_apeslpx, false ); /* skip flash mode */
        gpio_write( cmt_rst_rq, false ); /* prevent current drain */

        switch ( rapu_type )
        {
            case RapuType.TYPE_2:
                gpio_write( cmt_en, false );
                /* 15 ms needed for ASIC poweroff */
                Posix.usleep( 20000 );
                gpio_write( cmt_en, true );
                break;

            case RapuType.TYPE_1:
                gpio_write( cmt_en, false );
                gpio_write( cmt_bsi, false ); /* toggle BSI visible to modem */
                gpio_write( cmt_rst, false ); /* Assert PURX */
                gpio_write( cmt_en, true );   /* Press "power key" */
                gpio_write( cmt_rst, true );  /* Release CMT to boot */
                break;

            default:
                logger.warning( @"unknown rapu type $rapu_type" );
                return false;
        }

        gpio_write( cmt_rst_rq, true );

        Posix.sleep(5);

        switch ( rapu_type )
        {
            case RapuType.TYPE_2:
                break;

            case RapuType.TYPE_1:
                gpio_write( cmt_en, false );  /* release "power key" */
                break;
        }

        return true;
    }

    public bool poweroff()
    {
        assert( logger.debug( "lowlevel_nokia900_poweroff()" ) );

        gpio_write( cmt_apeslpx, false ); /* skip flash mode */
        gpio_write( cmt_rst_rq, false );  /* prevent current drain */

        switch ( rapu_type )
        {
            case RapuType.TYPE_2:
                gpio_write( cmt_en, false ); /* Power off */
                break;

            case RapuType.TYPE_1:
                gpio_write( cmt_en, false );  /* release "power key" */
                gpio_write( cmt_rst, false ); /* force modem to reset state */
                gpio_write( cmt_rst, true );  /* release modem to be powered off by bootloader */
                break;
        }

        return true;
    }

    public bool suspend()
    {
        assert( logger.debug( "lowlevel_nokia900_suspend()" ) );
        return true;
    }

    public bool resume()
    {
        assert( logger.debug( "lowlevel_nokia900_resume()" ) );
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
