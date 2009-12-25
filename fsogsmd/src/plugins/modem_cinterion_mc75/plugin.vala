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

namespace CinterionMc75
{
    const string MODULE_NAME = "fsogsm.modem_cinterion_mc75";
    const string CHANNEL_NAMES[] = { "call", "main", "misc" };
}

class CinterionMc75.Modem : FsoGsm.AbstractModem
{
    public override string repr()
    {
        return "<>";
    }

    public override void configureData()
    {
        assert( modem_data != null );

        // mc75 has a SIM READY signal, enable via AT^SSET
        modem_data.simHasReadySignal = true;

        registerCommandSequence( "main", "init", new CommandSequence( {
            "+CREG=2",
            "^SSET=1" } ) );

        // modem specific init sequences
        var seq = modem_data.cmdSequences;
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

    protected override FsoGsm.UnsolicitedResponseHandler createUnsolicitedHandler()
    {
        return new CinterionMc75.UnsolicitedResponseHandler();
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
    debug( "mc75 fso_factory_function" );
    return CinterionMc75.MODULE_NAME;
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
