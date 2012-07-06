/*
 * Copyright (C) 2011 Klaus 'mrmoku' Kurzmann
 * Copyright (C) 2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
using Gee;
using FsoGsm;

/**
 * @class Gtm601.Modem
 *
 * This modem plugin supports standard AT modems that do not use a multiplexing mode.
 *
 **/
class Gtm601.Modem : FsoGsm.AbstractModem
{
    private const string CHANNEL_NAME = "main";
    private const string URC_CHANNEL_NAME = "urc";

    construct
    {
        this.signalStatusChanged.connect( onModemStatusChange );
    }

    public override string repr()
    {
        return "<>";
    }

    public override void configureData()
    {
        assert( modem_data != null );

        modem_data.simHasReadySignal = true; // $QCSIMSTAT
        modem_data.simReadyTimeout = 5; /* seconds */

        atCommandSequence( "MODEM", "init" ).append( {
            "$QCSIMSTAT=1",          /* enable sim status report */
            "_OSQI=1"                /* signal strength updates */
        } );

        registerAtCommandSequence( "main", "init", new AtCommandSequence( {
            """+CGEREP=2,1""",
            """+CGREG=2""",
            """+CLIP=1""",
            """+CREG=2""",
            """+COLP=0""",
            """+CSSN=1,1""",
            """+CTZU=1""",
            """+CTZR=1"""
        } ) );

        registerAtCommandSequence( "main", "suspend", new AtCommandSequence( {
            """_OSQI=0""" /* disable signal strength updates */
        } ) );

        registerAtCommandSequence( "main", "resume", new AtCommandSequence( {
            """_OSQI=1""" /* enable signal strength updates */
        } ) );
    }

    protected override void createChannels()
    {
        var transport = modem_transport_spec.create();
        var parser = new FsoGsm.StateBasedAtParser();
        new AtChannel( this, CHANNEL_NAME, transport, parser );

        var modem_urc_access = FsoFramework.theConfig.stringValue( "fsogsm.modem_option_gtm601", "modem_urc_access", "" );
        if ( modem_urc_access.length > 0 )
        {
            transport = FsoFramework.TransportSpec.parse( modem_urc_access ).create();
            parser = new FsoGsm.StateBasedAtParser();
            new AtChannel( this, URC_CHANNEL_NAME, transport, parser );
        }
    }

    protected override FsoGsm.Channel channelForCommand( FsoGsm.AtCommand command, string query )
    {
        // nothing to round-robin here as gmt601 only has one channel
        return channels[ CHANNEL_NAME ];
    }

    protected override void registerCustomMediators( HashMap<Type,Type> mediators )
    {
        Gtm601.registerCustomMediators( mediators );
    }

    protected override FsoGsm.UnsolicitedResponseHandler createUnsolicitedHandler()
    {
        return new Gtm601.UnsolicitedResponseHandler( this );
    }

    protected override void registerCustomAtCommands( HashMap<string,FsoGsm.AtCommand> commands )
    {
        PlusCOPS.providerNameDeliveredInConfiguredCharset = true;

        Gtm601.registerCustomAtCommands( commands );
    }

    protected override FsoGsm.SmsHandler createSmsHandler()
    {
        return new Gtm601.SmsHandler( this );
    }

    private void onModemStatusChange( FsoGsm.Modem.Status status )
    {
        switch ( status )
        {
            case FsoGsm.Modem.Status.RESUMING:
                /**
                 * Poll for new SMS on the SIM.
                 * On the GTA04 we get no AT command for incoming sms' during suspend but
                 * the phone awakes and the SMS is available on the SIM, so we can poll.
                 **/
                var smshandler = smshandler as AtSmsHandler;
                smshandler.syncWithSim();
                break;

            default:
                break;
        }
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
    FsoFramework.theLogger.debug( "fsogsm.option_gtm601 fso_factory_function" );
    return "fsogsmd.modem_option_gtm601";
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
