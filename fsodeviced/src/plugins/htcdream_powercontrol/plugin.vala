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

namespace HtcDream
{

/**
 * GPS power control for HTC Dream
 **/
class GpsPowerControl : FsoDevice.BasePowerControl
{
    private FsoFramework.Subsystem subsystem;
    private string sysfsnode;
    private string name;

    bool on;

    public BluetoothPowerControl( FsoFramework.Subsystem subsystem )
    {
        base( Path.build_filename( sysfsnode, "" ) );
        this.subsystem = subsystem;
        this.sysfsnode = sysfsnode;
        this.name = Path.get_basename( sysfsnode );

        subsystem.registerServiceName( FsoFramework.Device.ServiceDBusName );
        subsystem.registerServiceObject( FsoFramework.Device.ServiceDBusName,
                                         "%s/%u".printf( FsoFramework.Device.PowerControlServicePath, counter++ ),
                                         this );


        logger.info( "Created." );
    }

    public override bool getPower()
    {
        return on;
    }

    public override void setPower( bool on )
    {
        if ( this.on == on )
        {
            return;
        }

        // FIXME: Start/Stop GPS Thread
    }
}

} /* namespace */

internal List<FsoDevice.BasePowerControlResource> resources;
internal List<FsoDevice.BasePowerControl> instances;
internal static string sysfs_root;

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    var o = new HtcDream.GpsPowerControl( subsystem );
    instances.append( o );
#if WANT_FSO_RESOURCE
    resources.append( new FsoDevice.BasePowerControlResource( o, "GPS", subsystem ) );
#endif

    return "fsodevice.htcdream_powercontrol";
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsodevice.htcdream_powercontrol fso_register_function()" );
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
