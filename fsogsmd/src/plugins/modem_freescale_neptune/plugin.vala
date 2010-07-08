/*
 * Copyright (C) 2010  Antonio Ospite <ospite@studenti.unina.it>
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

namespace FreescaleNeptune
{
    const string MODULE_NAME = "fsogsm.modem_freescale_neptune";
    // FIXME: rename main to call ??
    const string CHANNEL_NAMES[] = { "main", "sms", "sim", "misc" };
}

/**
 * @class FreescaleNeptune.Modem
 *
 * This modem plugin supports the Freescale neptune chipset used on Motorola EzX
 * phones.
 **/
class FreescaleNeptune.Modem : FsoGsm.AbstractModem
{
    public string revision { get; set; default = "unknown"; }

    construct
    {
        /* Init the modem */
        logger.info("Called FreescaleNeptune.Modem construct");
    }

    public override string repr()
    {
        return @"<$(channels.size)C>";
    }

    public override void configureData()
    {
        /* XXX: we could send these here too, but right now doing something
         * like in http://git.ao2.it/fso-scripts.git/?a=blob;f=fso-auth.py;h=0fc26f98f7f31a414c46dbfc8e6d27ba3e3f8a77
         * would fail because +CPIN? is sent before +EPOM completes...
            """+EPOM=1,0""",
            """+EAPF=12,1,0""",
         *   so we put these commands in the lowlevel plugin
         */

        // sequence for initializing the channel
        registerAtCommandSequence( "main", "init", new AtCommandSequence( {
            // GSM unsolicited
            """+CRC=1""",
            """+CLIP=1""",
            """+COLP=1""",
            """+CCWA=1""",
            """+CSSN=1,1""",
            """+CTZU=1""",
            """+CTZR=1""",
            """+CREG=2""",
            """+CAOC=2""",
            // GPRS unsolicited
            """+CGEREP=2,1""",
            """+CGREG=2"""
        } ) );

        // sequence for initializing the channel
        registerAtCommandSequence( "sms", "unlocked", new AtCommandSequence( {
            """+CRRM""",
            //FIXME if this returns an error, we might have no SIM inserted
            """+EPMS?""",
            """+EMGL=4"""
        } ) );

        // sequence for initializing the channel
        registerAtCommandSequence( "misc", "init", new AtCommandSequence( {
            """+USBSTAT=255,1"""
        } ) );
    }

    protected override void createChannels()
    {
        logger.info("Create Freescale Neptune channels");

        var muxnode_prefix = config.stringValue( MODULE_NAME, "muxnode_prefix");

        for ( int i = 0; i < CHANNEL_NAMES.length; ++i ) {
            var channel = CHANNEL_NAMES[i];
            var dlci = config.stringValue( MODULE_NAME, @"dlci_$(channel)" );
            if ( dlci != "" ) {
                var muxnode = @"$(muxnode_prefix)$(dlci)";
                var transport = FsoFramework.Transport.create("serial", muxnode, 115200);
                new AtChannel( channel, transport, new FsoGsm.StateBasedAtParser() );
            } else {
                logger.warning( @"No dlci for channel \"$(channel)\"" );
            }
        }
    }

    protected override void registerCustomMediators( HashMap<Type,Type> mediators )
    {
        logger.info("Register Neptune mediators");
        FreescaleNeptune.registerNeptuneMediators( mediators );
    }

    protected override FsoGsm.UnsolicitedResponseHandler createUnsolicitedHandler()
    {
        return new FreescaleNeptune.UnsolicitedResponseHandler();
    }

    protected override FsoGsm.Channel channelForCommand( FsoGsm.AtCommand command, string query )
    {
        // FIXME: check what commands are to be sent to each channel
        return channels[ "main" ];
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
    FsoFramework.theLogger.debug( "fsogsm.freescale_neptune fso_factory_function" );
    return FreescaleNeptune.MODULE_NAME;
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
