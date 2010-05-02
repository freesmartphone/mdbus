/*
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

/**
 * @class QualcommHtc.Modem
 *
 * This modem plugin supports the Qualcomm MSM 7xxx chipset with HTC firmware as found
 * in devices such as
 * - HTC Dream (T-Mobile G1, Google ADP-1)
 * - HTC Magic
 * - HTC Raphael
 * - HTC Blackstone
 * - HTC Diamond
 *
 * The HTC firmware comes with some bugs in the parser and non-standard AT extensions,
 * which is the reason we can't cover these modems with the 'singleline' plugin.
 **/
class QualcommHtc.Modem : FsoGsm.AbstractModem
{
    private const string CHANNEL_NAME = "main";

    public override string repr()
    {
        return "<>";
    }

    public override void configureData()
    {
        assert( modem_data != null );
        modem_data.simHasReadySignal = true;

        // sequence for initializing the channel
        registerAtCommandSequence( "main", "init", new AtCommandSequence( {
            """+CLIP=1""",
            """+COLP=0""",
            """+CCWA=1""",
            """+CSSN=1,1""",
            """+CTZU=1""",
            """+CTZR=1""",
            """+CREG=2""",
            """+CGREG=2""",
            """+CGEREP=2,1""",

            """+HTCCTZR=2"""
        } ) );

        // sequence for when the modem is registered
        registerAtCommandSequence( "main", "registered", new AtCommandSequence( {
            """+CNMI=2,1,2,2,1""" // deliver SMS via SIM
        } ) );

        // sequence for suspending the channel
        registerAtCommandSequence( "main", "suspend", new AtCommandSequence( {
            """+CREG=0""",
            """+CGREG=0""",
            """+CGEREP=0,0"""
        } ) );

        // sequence for resuming the channel
        registerAtCommandSequence( "main", "resume", new AtCommandSequence( {
            """+CREG=2""",
            """+CGREG=2""",
            """+CGEREP=2,1"""
        } ) );
    }

    protected override void createChannels()
    {
        var transport = FsoFramework.Transport.create( modem_transport, modem_port, modem_speed );
        var parser = new FsoGsm.HtcAtParser();
        new AtChannel( CHANNEL_NAME, transport, parser );
    }

    protected override FsoGsm.Channel channelForCommand( FsoGsm.AtCommand command, string query )
    {
        // nothing to do here as qualcomm_htc only has one channel
        return channels[ CHANNEL_NAME ];
    }

    protected override FsoGsm.UnsolicitedResponseHandler createUnsolicitedHandler()
    {
        return new QualcommHtc.UnsolicitedResponseHandler();
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
    FsoFramework.theLogger.debug( "fsogsm.qualcomm_htc fso_factory_function" );
    return "fsogsmd.modem_qualcomm_htc";
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
