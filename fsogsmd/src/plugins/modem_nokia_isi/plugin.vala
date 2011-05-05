/*
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
using Gee;
using FsoGsm;

namespace NokiaIsi
{
    const string MODULE_NAME = "fsogsm.modem_nokia_isi";
    NokiaIsi.Modem modem;
    GIsiComm.ModemAccess isimodem;
}

/**
 * @class NokiaIsi.Modem
 *
 * This modem plugin supports the Nokia ISI chipset used on Nokia N900
 *
 * The modem uses a binary protocol implemented in libgisi / libgisicomm
 **/
class NokiaIsi.Modem : FsoGsm.AbstractModem
{
    public enum RapuType
    {
        TYPE_1,
        TYPE_2
    }

    private const string ISI_CHANNEL_NAME = "main";

    private const string GPIO_SWITCH = "/sys/devices/platform/gpio-switch";
    private const string DEV_CMT = "/dev/cmt";
    private const string GPIO_DIR = "/sys/class/gpio";

    private const int cmt_en = 0;
    private const int cmt_rst_rq = 1;
    private const int cmt_rst = 2;
    private const int cmt_bsi = 3;
    private const int cmt_apeslpx = 4;

    private RapuType rapu_type;

    private bool have_gpio_switch;
    private bool have_gpio[5];

    private bool startup_sequence = false;
    private bool handle_modem_power = true;


    construct
    {
        if ( modem_transport != "phonet" )
        {
            logger.critical( "ISI: This modem plugin only supports the PHONET transport" );
            return;
        }
        if ( Linux.Network.if_nametoindex( modem_port ) == 0 )
        {
            logger.critical( @"Interface $modem_port not available" );
        }

        handle_modem_power = config.boolValue( MODULE_NAME, "handle_modem_power", true );

        NokiaIsi.modem = this;
        NokiaIsi.isimodem = new GIsiComm.ModemAccess( modem_port );
        NokiaIsi.isimodem.netlinkChanged.connect( onNetlinkChanged );
        gpio_probe();
    }

    public override string repr()
    {
        return @"<$modem_transport:$modem_port>";
    }

    protected override bool powerOn()
    {
        if ( !base.powerOn() )
            return false;

        assert( logger.debug( "modem_nokia_isi: powerOn" ) );

        if ( !handle_modem_power )
            return true;

        // always turn off first
        _power_off();

        startup_sequence = true;

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

        return true;
    }

    protected override void powerOff()
    {
        base.powerOff();

        assert( logger.debug( "modem_nokia_isi: powerOff" ) );

        if ( !handle_modem_power )
            return;

        _power_off();
    }

    protected void _power_off()
    {
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
    }

    protected override UnsolicitedResponseHandler createUnsolicitedHandler()
    {
        // NOTE: we define our base unsolicited handler in our commandqueue,
        // as the base on is very AT command specific atm. Need to change
        // this somewhere in the future ...
        return null;
    }

    protected override CallHandler createCallHandler()
    {
		return new IsiCallHandler();
    }

    protected override SmsHandler createSmsHandler()
    {
        return null;
    }

    protected override PhonebookHandler createPhonebookHandler()
    {
		return null;
    }

    protected override WatchDog createWatchDog()
    {
		return null;
    }

    protected override void createChannels()
    {
        new IsiChannel( ISI_CHANNEL_NAME, new IsiTransport( modem_port ) );
    }

    protected override FsoGsm.Channel channelForCommand( FsoGsm.AtCommand command, string query )
    {
        return null;
    }

    protected override void registerCustomMediators( HashMap<Type,Type> mediators )
    {
        mediators.clear(); // we don't need the default AT mediators
        NokiaIsi.registerMediators( mediators );
    }

    private void onNetlinkChanged( bool online )
    {
        if ( handle_modem_power && online && startup_sequence )
        {
            gpio_write( cmt_rst_rq, false );
            if ( rapu_type == RapuType.TYPE_1 )
                gpio_write( cmt_en, false );  /* release "power key" */

            startup_sequence = false;
        }
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
}

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    FsoFramework.theLogger.debug( "nokia_isi fso_factory_function" );
    return "fsogsm.modem_nokia_isi";
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    // do not remove this function
}

/**
 * This function gets called on plugin load time.
 * @return false, if the plugin operating conditions are present.
 * @note Some versions of glib contain a bug that leads to a SIGSEGV
 * in g_module_open, if you return true here.
 **/
/*public static bool g_module_check_init( void* m )
{
    var ok = FsoFramework.FileHandling.isPresent( Kernel26.SYS_CLASS_LEDS );
    return (!ok);
}
*/

// vim:ts=4:sw=4:expandtab
