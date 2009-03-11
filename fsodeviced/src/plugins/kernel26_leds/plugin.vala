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

// FIXME: For some reason the dbus interface code doesn't work, if not included here :(
namespace XsoFramework { namespace Device
{
    [DBus (name = "org.freesmartphone.Device.LED")]
    public abstract interface LED
    {
        public abstract string GetName();
        public abstract void SetBrightness( int brightness );
        public abstract void SetBlinking( int delay_on, int delay_off );
        public abstract void SetNetworking( string iface, string mode );
    }
} }

namespace Kernel26
{

static const string SYS_CLASS_LEDS = "/sys/class/leds";

class Led : XsoFramework.Device.LED, Object
{
    FsoFramework.Subsystem subsystem;
    static FsoFramework.Logger logger;

    string sysfsnode;

    static uint counter;

    public Led( FsoFramework.Subsystem subsystem, string sysfsnode )
    {
        this.subsystem = subsystem;
        this.sysfsnode = sysfsnode;

        if ( logger == null )
            logger = FsoFramework.createLogger( "fsodevice.kernel26_leds" );
        logger.info( "created new Led for %s".printf( sysfsnode ) );

        subsystem.registerServiceName( FsoFramework.Device.ServiceDBusName );
        subsystem.registerServiceObject( FsoFramework.Device.ServiceDBusName,
                                         "%s/%u".printf( FsoFramework.Device.LedServicePath, counter++ ),
                                         this );
    }

    //
    // FsoFramework.Device.LED
    //
    public string GetName()
    {
        return sysfsnode;
    }

    public void SetBrightness( int brightness )
    {
        //...
    }

    public void SetBlinking( int delay_on, int delay_off )
    {
        //...
    }
    public void SetNetworking( string iface, string mode )
    {
        //...
    }
}

} /* namespace */

List<Kernel26.Led> instances;

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    // scan sysfs path for leds
    var dir = new Dir( Kernel26.SYS_CLASS_LEDS );
    var entry = dir.read_name();
    while ( entry != null )
    {
        var filename = Path.build_filename( Kernel26.SYS_CLASS_LEDS, entry );
        instances.append( new Kernel26.Led( subsystem, filename ) );
        entry = dir.read_name();
    }
    return "fsodevice.kernel26_leds";
}
