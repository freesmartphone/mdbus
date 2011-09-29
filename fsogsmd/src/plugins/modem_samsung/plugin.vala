/*
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 * Copyright (C) 2010 Denis 'GNUtoo' Carikli <GNUtoo@no-log.org>
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
 * @class Samsung
 **/
class Samsung.Modem : FsoGsm.AbstractModem
{
    private const string MAIN_CHANNEL_NAME = "main";

    construct
    {
    }

    public override string repr()
    {
        return @"<>";
    }

    protected override bool powerOn()
    {
        base.powerOn();
        return true;
    }

    protected override void powerOff()
    {
        base.powerOff();
    }

    protected override UnsolicitedResponseHandler createUnsolicitedHandler()
    {
        // NOTE: we define our base unsolicited handler in our commandqueue,
        // as the base on is very AT command specific atm. Need to change
        // this somewhere in the future ...
        return null;
    }

    protected override CallHandler createCallHandler()
    {
        return null;
    }

    protected override SmsHandler createSmsHandler()
    {
        return null;
    }

    protected override PhonebookHandler createPhonebookHandler()
    {
        return null;
    }

    protected override void createChannels()
    {
        // new SamsungIpc.Channel( IPC_CHANNEL_NAME, new IsiTransport( modem_port ) );
    }

    protected override FsoGsm.Channel channelForCommand( FsoGsm.AtCommand command, string query )
    {
        return null;
    }

    protected override void registerCustomMediators( HashMap<Type,Type> mediators )
    {
        mediators.clear(); // we don't need the default AT mediators
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
    FsoFramework.theLogger.debug( "samsung fso_factory_function" );
    return "fsogsm.modem_samsung";
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
