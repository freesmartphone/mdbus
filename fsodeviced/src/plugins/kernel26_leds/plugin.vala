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

namespace Kernel26
{

static const string SYS_CLASS_LEDS = "/sys/class/leds";

class Led
{
    static FsoFramework.Logger logger;

    public Led( string filename )
    {
        if ( logger == null )
            logger = FsoFramework.createLogger( "fsodevice.kernel26_leds" );
        logger.info( "created new Led for %s".printf( filename ) );
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
string fso_factory_function() throws Error
{
    // scan sysfs path for leds
    var dir = new Dir( Kernel26.SYS_CLASS_LEDS );
    var entry = dir.read_name();
    while ( entry != null )
    {
        var filename = Path.build_filename( Kernel26.SYS_CLASS_LEDS, entry );
        instances.append( new Kernel26.Led( filename ) );
        entry = dir.read_name();
    }
    return "fsodevice.kernel26_leds";
}
