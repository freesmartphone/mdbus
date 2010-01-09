/**
 * Copyright (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
    const string CHANNEL_NAMES[] = { "call", "main", "data" };
}

/**
 * @class CinterionMc75.Modem
 *
 * This modem plugin supports a wide variety of SIEMENS / CINTERION industrial
 * modems, however the main target is the mc75(i).
 *
 * We're operating this modem in basic MUX mode (NOT the SIEMENS proprietary MUX mode)
 * and use all of its three channels:
 * 'call': First channel will be reserved for calling commands (ATD and friends).
 * 'main': Second channel will be used for receiving URC and sending misc. commands.
 * 'data': Third channel will be used for data connectivity (ppp), but also misc. commands,
 * when the data connection is not in use.
 *
 **/
class CinterionMc75.Modem : FsoGsm.AbstractModem
{
    public override string repr()
    {
        return @"<$(channels.size)C>";
    }

    public override void configureData()
    {
        assert( modem_data != null );

        // mc75 has a SIM READY signal, can be enabled via ^SSET=1
        modem_data.simHasReadySignal = true;

        registerCommandSequence( "main", "init", new CommandSequence( {
            """+CREG=2""",              /* +CREG URC = enable */
            """^SM20=0,0""",            /* M20 compatibility behavior = disable */
            """^SSET=1""",              /* ^SSIM_READY URC = enable */

            """^SIND="battchg",1""",    /* Include indicator in +CIND URC = enable */
            """^SIND="signal",1""",
            """^SIND="service",1""",
            """^SIND="sounder",1""",
            """^SIND="message",1""",
            """^SIND="call",1""",
            """^SIND="roam",1""",
            """^SIND="smsfull",1""",
            """^SIND="rssi",1""",
            """^SIND="audio",1""",
            """^SIND="simstatus",1""",
            """^SIND="vmwait1",1""",
            """^SIND="vmwait2",1""",
            """^SIND="ciphcall",1""",
            """^SIND="adnread",1""",
            """^SIND="eons",1""",
            """^SIND="nitz",1""",
            """^SIND="lsta",1""",
            """^SIND="band",1""",
            """^SIND="simlocal",1""",

            """+CMER=3,0,2,0"""         /* +CIND URC = enable */

        } ) );

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
    debug( "mc75 fso_register_function" );
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
