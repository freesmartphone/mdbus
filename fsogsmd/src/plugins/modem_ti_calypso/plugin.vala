/**
 * Copyright (C) 2009 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
using Gee;
using FsoGsm;

namespace TiCalypso
{
    const string MODULE_NAME = "fsogsm.modem_ti_calypso";
    const string CHANNEL_NAMES[] = { "call", "main", "urc", "data" };
}

/**
 * @class TiCalypso.Modem
 *
 * This modem plugin supports the TEXAS INSTRUMENTS Calypso chipset.
 *
 * We're operating this modem in advanced MUX mode and use all of its four channels:
 * 'call': First channel will be reserved for calling commands (ATD and friends).
 * 'main': Second channel will be used for misc. commands.
 * 'urc': Third channel will be used for receiving URCs.
 * 'data': Fourth channel will be used for data connectivity (ppp), but also misc. commands,
 * when the data connection is not in use.
 *
 **/
class TiCalypso.Modem : FsoGsm.AbstractModem
{
    private string powerNode;

    public override string repr()
    {
        return "<>";
    }

    public override void configureData()
    {
        assert( modem_data != null );
        modem_data.simHasReadySignal = true;

        // power node
        powerNode = config.stringValue( MODULE_NAME, "power_node", "unknown" );

        // init sequences
        //registerCommandSequence( "init", "call" );
    }

    protected override void setPower( bool on )
    {
        if ( powerNode == "unknown" )
        {
            return;
        }

        FsoFramework.FileHandling.write( "0\n", powerNode );
        Thread.usleep( 1000 * 1000 );
        if ( on )
        {
            FsoFramework.FileHandling.write( "1\n", powerNode );
            Thread.usleep( 1000 * 1000 );
        }
    }

    protected override void createChannels()
    {
        for ( int i = 0; i < CHANNEL_NAMES.length; ++i )
        {
            var transport = new FsoGsm.LibGsm0710muxTransport( i+1 );
            var parser = new FsoGsm.StateBasedAtParser();
            new Channel( CHANNEL_NAMES[i], transport, parser );
        }
    }

    protected override void registerCustomMediators( HashMap<Type,Type> mediators )
    {
    }

    protected override void registerCustomAtCommands( HashMap<string,FsoGsm.AtCommand> commands )
    {
        TiCalypso.registerCustomAtCommands( commands );
    }

    protected override FsoGsm.UnsolicitedResponseHandler createUnsolicitedHandler()
    {
        return new TiCalypso.UnsolicitedResponseHandler();
    }

    protected override FsoGsm.Channel channelForCommand( FsoGsm.AtCommand command, string query )
    {
        return channels[ "main" ];
    }

    public void responseHandler( FsoGsm.AtCommand command, string[] response )
    {
        debug( "handler called with '%s'", response[0] );
        assert_not_reached();
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
    debug( "fsogsm.ti_calypso fso_factory_function" );
    return TiCalypso.MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    debug( "fsogsm.ti_calypso fso_register_function" );
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
