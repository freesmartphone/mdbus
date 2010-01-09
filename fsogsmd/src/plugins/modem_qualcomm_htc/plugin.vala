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

/**
 * @class QualcommHtc.Modem
 *
 * This modem plugin supports the Qualcomm MSM 7xxx chipset with HTC firmware.
 *
 * HTC firmware comes with some bugs in the parser and non-standard AT extensions,
 * therefore we can't cover these modems with the 'singleline' plugin.
 **/
class QualcommHtc.Modem : FsoGsm.AbstractModem
{
    private const string CHANNEL_NAME = "main";

    public override string repr()
    {
        return "<>";
    }

    protected override void createChannels()
    {
        var transport = FsoFramework.Transport.create( modem_transport, modem_port, modem_speed );
        var parser = new FsoGsm.HtcAtParser();
        var chan = new Channel( CHANNEL_NAME, transport, parser );
    }

    protected override FsoGsm.Channel channelForCommand( FsoGsm.AtCommand command, string query )
    {
        // nothing to do here as qualcomm_htc only has one channel
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
    debug( "qualcomm_htc fso_factory_function" );
    return "fsogsmd.modem_qualcomm_htc";
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    debug( "qualcomm_htc fso_register_function" );
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
