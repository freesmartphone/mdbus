/*
 * Copyright (C) 2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
using sflphone;

const string SFLPHONE_BUS_NAME = "org.sflphone.SFLphone";
const string SFLPHONE_PATH_CONFIGURATION = "/org/sflphone/SFLphone/ConfigurationManager";
const string SFLPHONE_PATH_CALLMANAGER = "/org/sflphone/SFLphone/CallManager";

/**
 * @class Phone.VoIP.SflPhone
 **/
class Phone.VoIP.SflPhone : FsoPhone.ICommunicationProvider, FsoPhone.IVoiceCallProvider, FsoFramework.AbstractObject
{
    public const string MODULE_NAME = "fsophone.technology_voip_sflphone";

    FsoFramework.Subsystem subsystem;
    SFLphone.ConfigurationManager configuration;
    SFLphone.CallManager callmanager;

    public SflPhone( FsoFramework.Subsystem subsystem )
    {
        this.subsystem = subsystem;
        logger.info( @"Created" );
    }

    public override string repr()
    {
        return "<>";
    }

    public async void probe() throws Error
    {
        assert( logger.debug( "Probing for SFLphone..." ) );

        configuration = yield Bus.get_proxy<SFLphone.ConfigurationManager>( BusType.SESSION, SFLPHONE_BUS_NAME, SFLPHONE_PATH_CONFIGURATION );
        callmanager = yield Bus.get_proxy<SFLphone.CallManager>( BusType.SESSION, SFLPHONE_BUS_NAME, SFLPHONE_PATH_CALLMANAGER );

        assert( logger.debug( "SFLphone found, proxies registered" ) );
    }
}

internal Phone.VoIP.SflPhone instance;

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    return Phone.VoIP.SflPhone.MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsophone.technology_voip_sflphone fso_register_function" );
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
