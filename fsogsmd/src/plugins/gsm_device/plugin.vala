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

namespace GsmDevice { const string MODULE_NAME = "fsogsm.gsm_device"; }

class GsmDevice.Device : GLib.Object
{
    FsoFramework.Subsystem subsystem;
    FsoGsm.Modem modem;
    static FsoFramework.Logger logger;
    static FsoFramework.SmartKeyFile config;

    static construct
    {
        logger = FsoFramework.createLogger( MODULE_NAME );
        config = FsoFramework.theMasterKeyFile();
    }

    public Device( FsoFramework.Subsystem subsystem )
    {
        logger.setReprDelegate( this.repr );
        logger.debug( "ready" );

        var modemtype = config.stringValue( MODULE_NAME, "modem_type", "DummyModem" );
        assert( modemtype != "DummyModem" ); // dummy modem not implemented yet

        //TODO gather type automatically

        switch ( modemtype )
        {
            case "ti_calypso":
                Type t = Type.from_name( "TiCalypsoModem" );
                assert( t != Type.INVALID );
                debug( "type has id %p", (void*)t );
/*                var typeclass = type.class_ref();
                debug( "typeclass name is '%s'", type.name() );
                assert( type.is_interface() );
                modem = (FsoGsm.Modem) Object.new( Type.from_name( "TiCalypsoModem" ) ); //TiCalypso.Modem();*/
                break;
            default:
                assert_not_reached();
        }
    }

    public string repr()
    {
        return "<GsmDevice>";
    }

}

List<GsmDevice.Device> instances;

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    instances.append( new GsmDevice.Device( subsystem ) );
    return GsmDevice.MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    debug( "yo" );
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
