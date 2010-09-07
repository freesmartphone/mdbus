/*
 * Copyright (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *                    2010 Sebastian Krzyszkowiak <seba.dos1@gmail.com>
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

namespace Proximity
{
    internal const string NEAR = "closed";
    internal const string FAR = "open";

class N900 : FreeSmartphone.Device.Proximity,
                FreeSmartphone.Device.PowerControl,
                FsoFramework.AbstractObject
{
    FsoFramework.Subsystem subsystem;

    private string node;

    FsoFramework.Async.ReactorChannel input;

    public N900( FsoFramework.Subsystem subsystem, string node )
    {
        this.subsystem = subsystem;
        this.node = node;

        if ( !FsoFramework.FileHandling.isPresent( this.node ) )
        {
            logger.error( @"Sysfs class is damaged, missing $(this.node); skipping." );
            return;
        }

        var fd = Posix.open( GLib.Path.build_filename( this.node, "state" ) , Posix.O_RDONLY );
        if ( fd == -1 )
        {
            logger.error( @"Can't open $(this.node): $(Posix.strerror(Posix.errno))" );
            return;
        }

        input = new FsoFramework.Async.ReactorChannel.rewind( fd, onInputEvent, sizeof( Linux.Input.Event ) );

        subsystem.registerServiceName( FsoFramework.Device.ServiceDBusName );
        subsystem.registerServiceObjectWithPrefix(
            FsoFramework.Device.ServiceDBusName,
            FsoFramework.Device.ProximityServicePath,
            this );

        logger.info( "Created" );

    }

    public override string repr()
    {
        return @"<$node>";
    }

    private void onInputEvent( void* data, ssize_t length )
    {
        //var event = (Linux.Input.Event*) data;
        //if ( event->type != 4 || event->code != 1 )
        //{
        //    assert( logger.debug( @"Unknown event w/ type $(event->type) and code $(event->code); ignoring" ) );
        //    return;
        //}

        var event = (string) data;

        // send dbus signal
        this.proximity( event == "closed" ? 100 : 0 );
    }

    //
    // FreeSmartphone.Device.Proximity (DBUS API)
    //
    public async void get_proximity( out int proximity, out int timestamp ) throws FreeSmartphone.Error, DBus.Error
    {
        proximity = -1;
        timestamp = 0;
    }

    //
    // FreeSmartphone.Device.PowerControl (DBUS API)
    //
    public async bool get_power() throws DBus.Error
    {
        //var contents = FsoFramework.FileHandling.read( powernode ) ?? "";
        //return contents.strip() == "1";
	return true; // TODO
    }

    public async void set_power( bool on ) throws DBus.Error
    {
        //var contents = on ? "1" : "0"; # TODO
        //FsoFramework.FileHandling.write( contents, powernode );
    }

}

} /* namespace */

static string sysfs_root;
Proximity.N900 instance;

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    // grab sysfs paths
    var config = FsoFramework.theConfig;
    sysfs_root = config.stringValue( "cornucopia", "sysfs_root", "/sys" );
    var dirname = GLib.Path.build_filename( sysfs_root, "devices", "platform", "gpio-switch", "proximity" );
    if ( FsoFramework.FileHandling.isPresent( dirname ) )
    {
        instance = new Proximity.N900( subsystem, dirname );
    }
    else
    {
        FsoFramework.theLogger.error( "No proximity device found; proximity object will not be available" );
    }
    return "fsodevice.proximity_n900";
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsodevice.proximity_n900 fso_register_function()" );
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
