/**
 * Copyright (C) 2009-2012 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

using FsoGsm;

/**
 * @class Dummy.Modem
 *
 * This modem plugin simulates a modem based on fixed parameters.
 *
 **/
class Dummy.Modem : FsoGsm.AbstractModem
{
    private const string CHANNEL_NAME = "main";

    public override string repr()
    {
        return "<>";
    }

    protected override FsoGsm.Channel channelForCommand( FsoGsm.AtCommand command, string query )
    {
        return (FsoGsm.Channel) null;
    }

    public async override bool open()
    {
        FsoGsm.modem_pin = "1234";
        advanceToState( FsoGsm.Modem.Status.ALIVE_SIM_LOCKED );
        return true;
    }

    public async override void close()
    {
    }

    protected override void registerCustomMediators( Gee.HashMap<Type,Type> mediators )
    {
        registerDummyMediators( mediators );
    }

    protected override CallHandler createCallHandler()
    {
        return new NullCallHandler();
    }

    protected override SmsHandler createSmsHandler()
    {
        return new NullSmsHandler();
    }

    protected override PhonebookHandler createPhonebookHandler()
    {
        return null;
    }

    protected override WatchDog createWatchDog()
    {
        return new NullWatchDog();
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
    FsoFramework.theLogger.debug( "fsogsm.dummy fso_factory_function" );
    return "fsogsmd.modem_dummy";
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
