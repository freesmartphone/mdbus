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

namespace SyncTime {
    const string MODULE_NAME = "fsotime.sync_time";
}

class SyncTime.Service : FsoFramework.AbstractObject
{
    FsoFramework.Subsystem subsystem;
    private Gee.HashMap<string,FsoTime.Source> sources;

    public Service( FsoFramework.Subsystem subsystem )
    {
        sources = new Gee.HashMap<string,FsoTime.Source>();
        var sourcenames = config.stringListValue( "fsotime", "sources", {} );
        foreach ( var source in sourcenames )
        {
            addSource( source );
        }

        /*
        subsystem.registerServiceName( FsoFramework.Time.ServiceDBusName );
        subsystem.registerServiceObject( FsoFramework.Time.ServiceDBusName, FsoFramework.Time.DeviceServicePath, this );
        */

        logger.info( @"Ready. Configured for $(sources.size) sources" );
    }

    public void addSource( string name )
    {
        var typename = "unknown";

        switch ( name )
        {
            case "ntp":
                typename = "SourceNtp";
                break;
            case "gps":
                typename = "SourceGps";
                break;
            case "gsm":
                typename = "SourceGsm";
                break;
            default:
                logger.warning( @"Unknown source $name - Ignoring" );
                return;
        }
        var sourceclass = Type.from_name( typename );
        if ( sourceclass == Type.INVALID  )
        {
            logger.warning( @"Can't find source $name (type=$typename) - plugin loaded?" );
            return;
        }
        sources[name] = (FsoTime.Source) Object.new( sourceclass );
        logger.info( @"Added source $name ($typename)" );
    }

    public override string repr()
    {
        return @"<$(sources.size)>";
    }
}

SyncTime.Service service;

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    service = new SyncTime.Service( subsystem );
    return SyncTime.MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    debug( "fsotime.sync_time fso_register_function" );
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
