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
    private string serialPort;
    private string speed;

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

        // sequence for initializing the channel urc
        registerCommandSequence( "urc", "init", new CommandSequence( {
            """+CLIP=1""",
            """+COLP=0""",
            """+CCWA=1""",
            """+CSSN=1,1""",
            """+CTZU=1""",
            """+CTZR=1""",
            """+CREG=2""",
            """+CGEREP=2,1""",
            """+CGREG=2""",

            """%CPI=3""",
            """%CSCN=1,2,1,2""",
            """%CPRI=1""",
            """%CNIV=1""",
            """%CSTAT=1""",
            """@ST="-26""""
        } ) );
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

            var transport = FsoFramework.Transport.create( modem_transport, modem_port, modem_speed );
            transport.open();

            assert( transport.isOpen() );

            var buf = new char[512];

            while ( true )
            {
                var bread = transport.writeAndRead( "ATE0Q0V1\r\n", 10, buf, 512 );
                buf[bread] = '\0';
                assert( logger.debug( "setPower: got %d bytes in buf: '%s'".printf( (int)bread, (string)buf ) ) );
                if ( bread > 3 && buf[bread-1] == '\n' && buf[bread-2] == '\r' && buf[bread-3] == 'K' && buf[bread-4] == 'O' )
                {
                    assert( logger.debug( "setPower: answer OK, ready to send first command" ) );
                    bread = transport.writeAndRead( "AT%SLEEP=2\r\n", 12, buf, 512 );
                    if ( bread > 3 && buf[bread-1] == '\n' && buf[bread-2] == '\r' && buf[bread-3] == 'K' && buf[bread-4] == 'O' )
                    {
                        assert( logger.debug( "setPower: answer OK, modem prepared for MUX commands" ) );
                        return;
                    }
                }
            }
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
