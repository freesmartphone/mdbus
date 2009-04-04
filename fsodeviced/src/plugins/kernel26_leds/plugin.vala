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

class Led : FsoFramework.Device.LED, GLib.Object
{
    FsoFramework.Subsystem subsystem;
    static FsoFramework.Logger logger;

    string sysfsnode;
    string brightness;
    string trigger;
    string triggers;
    string netdevs;

    static uint counter;

    public Led( FsoFramework.Subsystem subsystem, string sysfsnode )
    {
        if ( logger == null )
            logger = FsoFramework.createLogger( "fsodevice.kernel26_leds" );
        logger.info( "created new Led for %s".printf( sysfsnode ) );

        this.subsystem = subsystem;
        this.sysfsnode = sysfsnode;
        this.brightness = sysfsnode + "/brightness";
        this.trigger = sysfsnode + "/trigger";

        if ( !FsoFramework.FileHandling.isPresent( this.brightness ) ||
             !FsoFramework.FileHandling.isPresent( this.trigger ) )
        {
            logger.error( "^^^ sysfs class is damaged; skipping." );
            return;
        }

        subsystem.registerServiceName( FsoFramework.Device.ServiceDBusName );
        subsystem.registerServiceObject( FsoFramework.Device.ServiceDBusName,
                                         "%s/%u".printf( FsoFramework.Device.LedServicePath, counter++ ),
                                         this );
        // FIXME: remove in release code, can be done lazily
        initTriggers();
    }

    public void initTriggers()
    {
        if ( triggers == null )
        {
            triggers = FsoFramework.FileHandling.read( trigger );
            logger.info( "^^^ supports the following triggers: '%s'".printf( triggers ) );
        }
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
        if ( brightness > 255 )
            brightness = 255;
        if ( brightness < 0 )
            brightness = 0;

        FsoFramework.FileHandling.write( brightness.to_string(), this.brightness );
    }

    public void SetBlinking( int delay_on, int delay_off ) throws DBus.Error
    {
        initTriggers();
//         if ( !( "timer" in triggers ) )
//             throw new XsoFramework.Device.LedError.UNSUPPORTED( "kernel interface missing" );

        FsoFramework.FileHandling.write( "timer", this.trigger );
        FsoFramework.FileHandling.write( delay_on.to_string(), this.sysfsnode + "/delay_on" );
        FsoFramework.FileHandling.write( delay_off.to_string(), this.sysfsnode + "/delay_off" );

    }

    public void SetNetworking( string iface, string mode ) throws DBus.Error
    {
        initTriggers();

        if ( !FsoFramework.FileHandling.isPresent( "%s/%s".printf( sys_class_net, iface ) ) )
            return;
            //throw new FsoFramework.InvalidParameter( "interface %s not present".printf( iface ) );

            foreach ( var mode in mode.split( " " ) )
            {
            }
            /*
if m not in "link rx tx".split():
                         raise InvalidParameter( "Mode element %s not known. Available elements are 'link rx tx'" % m )
# do it
                         writeToFile( "%s/trigger" % self.node, "netdev" )
                         writeToFile( "%s/device_name" % self.node, str( interface.strip() ) )
                         writeToFile( "%s/mode" % self.node, str( mode.strip() ) )
        */
    }
}

} /* namespace */

static string sysfs_root;
static string sys_class_net;
static string sys_class_leds;
List<Kernel26.Led> instances;

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    // grab sysfs paths
    var config = FsoFramework.theMasterKeyFile();
    sysfs_root = config.stringValue( "cornucopia", "sysfs_root", "/sys" );
    sys_class_leds = "%s/class/leds".printf( sysfs_root );
    sys_class_net = "%s/class/net".printf( sysfs_root );

    // scan sysfs path for leds
    var dir = Dir.open( sys_class_leds );
    var entry = dir.read_name();
    while ( entry != null )
    {
        var filename = Path.build_filename( sys_class_leds, entry );
        instances.append( new Kernel26.Led( subsystem, filename ) );
        entry = dir.read_name();
    }
    return "fsodevice.kernel26_leds";
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