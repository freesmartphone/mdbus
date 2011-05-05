/*
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

class Source.Gps /* :  FsoTime.AbstractSource */
{
    public const string MODULE_NAME = "source_gps";

    FreeSmartphone.GSM.Network ogpsd_device;
    FreeSmartphone.Data.World odatad_world;
    /*

    DBus.IDBus dbus_dbus;


    construct
    {
        DBus.Connection conn = DBus.Bus.get( DBus.BusType.SYSTEM );

        ogpsd_device = conn.get_object( FsoFramework.GSM.ServiceDBusName,
                               FsoFramework.GSM.DeviceServicePath,
                               FsoFramework.GSM.ServiceFacePrefix + ".Network" ) as FreeSmartphone.GSM.Network;

        odatad_world = conn.get_object( FsoFramework.Data.ServiceDBusName,
                               FsoFramework.Data.WorldServicePath,
                               FsoFramework.Data.WorldServiceFace ) as FreeSmartphone.Data.World;

        dbus_dbus = conn.get_object( DBus.DBUS_SERVICE_DBUS,
                                DBus.DBUS_PATH_DBUS,
                                DBus.DBUS_INTERFACE_DBUS ) as DBus.IDBus;

        //FIXME: Work around bug in Vala (signal handlers can't be async yet)
        ogpsd_device.status.connect( (status) => { onGsmNetworkStatusSignal( status ); } );

        Idle.add( () => { triggerQuery(); return false; } );

        //NOTE: For debugging only
        //Idle.add( () => { testing(); return false; } );
    }

    private void testing()
    {
        var status = new GLib.HashTable<string,GLib.Value?>( GLib.str_hash, GLib.str_equal );
        //status.insert( "code", "310038" );
        status.insert( "code", "26203" );
        onGsmNetworkStatusSignal( status );
    }

    public override string repr()
    {
        return "";
    }

    private bool arrayContainsElement( string[] array, string element )
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
        // we don't want to autoactivate ogpsd, if it's not already present
        var names = yield dbus_dbus.ListNames();

        if ( arrayContainsElement( names, FsoFramework.GSM.ServiceDBusName ) )
        {
            try
            {
                var status = yield ogpsd_device.get_status();
                yield onGsmNetworkStatusSignal( status );
            }
            catch ( DBus.Error e )
            {
                logger.warning( @"Could not query the status from ogpsd: $(e.message)" );
            }
        }
        else
        {
            logger.warning( "ogpsd not present yet, waiting for signals..." );
        }
    }

    public override void triggerQuery()
    {
        triggerQueryAsync();
    }

    private async void onGpsLocationStatusSignal( GLib.HashTable<string,GLib.Value?> status )
    {
        logger.info( "Received GPS location status signal" );

        // ...

        //this.reportZone( (string)timezones.get_values().nth_data(0), this ); // SIGNAL
    }
    *
    */
}

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    FsoFramework.theLogger.debug( "fsotdl.source_gps fso_factory_function" );
    return Source.Gps.MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsotdl.source_gps fso_register_function" );
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
