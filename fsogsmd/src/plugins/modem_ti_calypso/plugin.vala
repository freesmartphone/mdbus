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

using FsoGsm;

namespace TiCalypso
{
    const string MODULE_NAME = "fsogsm.modem_ti_calypso";
    const string CHANNEL_NAME = "main";
}

class TiCalypso.Modem : FsoGsm.AbstractModem
{
    public override string repr()
    {
        return "<>";
    }

    protected override void configureData()
    {
        modem_data = new FsoGsm.Modem.Data();
        modem_data.simHasReadySignal = true;
    }

    protected override void createChannels()
    {
        var mode = config.stringValue( MODULE_NAME, "mode", "single" );
        if ( mode == "mux" )
        {
            logger.warning( "MUX mode not yet supported. Using single" );
        }

        var transport = FsoFramework.Transport.create( modem_transport, modem_port, modem_speed );
        var parser = new FsoGsm.StateBasedAtParser();
        var chan = new Channel( CHANNEL_NAME, transport, parser );
    }

    protected override FsoGsm.Channel channelForCommand( FsoGsm.AtCommand command, string query )
    {
        // nothing to do here as singleline only has one channel
        return channels[ CHANNEL_NAME ];
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
    debug( "calypso fso_factory_function" );
    return TiCalypso.MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    debug( "calypso fso_register_function" );
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
