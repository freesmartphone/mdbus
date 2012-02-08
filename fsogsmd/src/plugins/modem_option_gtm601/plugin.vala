/*
 * Copyright (C) 2011 Klaus 'mrmoku' Kurzmann
 * Copyright (C) 2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

    public override string repr()
    {
        return "<>";
    }

    public override void configureData()
    {
        assert( modem_data != null );

        modem_data.simHasReadySignal = true; // $QCSIMSTAT
        modem_data.simReadyTimeout = 5; /* seconds */

        theModem.atCommandSequence( "MODEM", "init" ).append( {
            "$QCSIMSTAT=1"          /* enable sim status report */
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

        var cnmiCommand = modem_data.simBuffersSms ? """+CNMI=2,1,2,1,1""" : """+CNMI=2,2,2,1,1""";

        // sequence for when the modem is registered
        registerAtCommandSequence( "main", "registered", new AtCommandSequence( {
            cnmiCommand,
            """+CSMS=1""" /* enable SMS phase 2 */
        } ) );

        registerAtCommandSequence( "main", "suspend", new AtCommandSequence( {
            """+CSQI=0""" /* disable signal strength updates */
        } ) );

        registerAtCommandSequence( "main", "resume", new AtCommandSequence( {
            """+CSQI=1""" /* enable signal strength updates */
        } ) );
    }

    protected override void createChannels()
    {
        var transport = FsoFramework.Transport.create( modem_transport, modem_port, modem_speed );
        var parser = new FsoGsm.StateBasedAtParser();
        new AtChannel( CHANNEL_NAME, transport, parser );
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
        return new Gtm601.UnsolicitedResponseHandler();
    }

    protected override void registerCustomAtCommands( HashMap<string,FsoGsm.AtCommand> commands )
    {

        var plusCops = theModem.createAtCommand<PlusCOPS>( "+COPS" );
        PlusCOPS.providerNameDeliveredInConfiguredCharset = true;

        Gtm601.registerCustomAtCommands( commands );
        var cmd = theModem.createAtCommand<Gtm601.UnderscoreOWANCALL>( "_OWANCALL" );
        FsoFramework.DataSharing.setValueForKey( "Gtm601.OWANCALL", cmd );
        var cmd2 = theModem.createAtCommand<Gtm601.UnderscoreOWANDATA>( "_OWANDATA" );
        FsoFramework.DataSharing.setValueForKey( "Gtm601.OWANDATA", cmd2 );
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
