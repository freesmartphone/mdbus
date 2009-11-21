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

using FsoTime;

namespace Source
{
    public const string MODULE_NAME_GSM = "source_gsm";
}

class Source.Gsm : FsoTime.AbstractSource
{
    FreeSmartphone.GSM.Network dev;
    DBus.IDBus obj;

    construct
    {
        DBus.Connection conn = DBus.Bus.get( DBus.BusType.SYSTEM );
        dev = conn.get_object( FsoFramework.GSM.ServiceDBusName,
                               FsoFramework.GSM.ServicePathPrefix + "/Device",
                               FsoFramework.GSM.ServiceFacePrefix + ".Network" ) as FreeSmartphone.GSM.Network;

        obj = conn.get_object( DBus.DBUS_SERVICE_DBUS,
                               DBus.DBUS_PATH_DBUS,
                               DBus.DBUS_INTERFACE_DBUS ) as DBus.IDBus;

        dev.status.connect( onGsmNetworkStatusSignal );
        
        Idle.add( () => { triggerQuery(); return false; } );
    }

    public override string repr()
    {
        return "";
    }

    public bool arrayContainsElement( string[] array, string element )
    {
        for ( int i = 0; i < array.length; ++i )
        {
            if ( array[i] == element )
            {
                return true;
            }
        }
        return false;
    }

    private async void triggerQueryAsync()
    {
        // we don't want to autoactivate ogsmd, if it's not already present
        var names = yield obj.ListNames();

        if ( arrayContainsElement( names, FsoFramework.GSM.ServiceDBusName ) )
        {
            try
            {
                var status = yield dev.get_status();
                onGsmNetworkStatusSignal( status );
            }
            catch ( DBus.Error e )
            {
                logger.warning( @"Could not query the status from ogsmd: $(e.message)" );
            }
        }
        else
        {
            logger.warning( "ogsmd not present yet, waiting for signals..." );
        }
    }

    public override void triggerQuery()
    {
        triggerQueryAsync();
    }

    private void onGsmNetworkStatusSignal( GLib.HashTable<string,GLib.Value?> status )
    {
        logger.info( "Received GSM network status signal" );
        /* TODO:
         * check 'code' (string) we are currently registered with
         * resolve it to a timezone
         * report to time controller
         */
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
    debug( "fsotime.source_gsm fso_factory_function" );
    return Source.MODULE_NAME_GSM;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    debug( "fsotime.source_gsm fso_register_function" );
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
