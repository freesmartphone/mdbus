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

/**
 * @class Kernel26.RfKillPowerControl
 *
 * Implementing org.freesmartphone.Device.PowerControl via Linux 2.6 rfkill API
 **/
class RfKillPowerControl : FreeSmartphone.Device.PowerControl, FsoFramework.AbstractObject
{
    protected static uint counter;

    private uint id;
    private Linux.RfKillType type;
    private bool softblock;
    private bool hardblock;

    private RfKillPowerControl( uint id, Linux.RfKillType type, bool softblock, bool hardblock )
    {
        subsystem.registerServiceName( FsoFramework.Device.ServiceDBusName );
        subsystem.registerServiceObject( FsoFramework.Device.ServiceDBusName,
                                         "%s/%u".printf( FsoFramework.Device.PowerControlServicePath, counter++ ),
                                         this );

        logger.info( "created." );
    }

    public override string repr()
    {
        return "<%u:%s:%s>".printf( id, softblock.to_string(), hardblock.to_string() );
    }

    private void init()
    {
        if ( fd != -1 )
        {
            return;
        }
        fd = Posix.open( Path.build_filename( devfs_root, "rfkill" ), Posix.O_RDWR );
        if ( fd == -1 )
        {
            logger.error( @"Can't open $devfs_root: $(strerror(errno)); rfkill plugin will not be operating" );
            return;
        }
        channel = new IOChannel.unix_new( fd );
        watch = channel.add_watch( IOCondition.IN | IOCondition.HUP, onActionFromRfKill );
    }

    protected static bool onActionFromRfKill( IOChannel source, IOCondition condition )
    {
        if ( ( condition & IOCondition.HUP ) == IOCondition.HUP )
        {
            error( "HUP on rfkill, will no longer get any notifications" );
            return false;
        }

        if ( ( condition & IOCondition.IN ) == IOCondition.IN )
        {
            assert( fd != -1 );
            var event = Linux.RfKillEvent();
            ssize_t bytesread = Posix.read( fd, &event, sizeof( Linux.RfKillEvent ) );
            if ( bytesread != sizeof( Linux.RfKillEvent ) )
            {
                warning( "can't read full rfkill event, got only %d bytes", (int)bytesread );
                return true;
            }
            message( "read %d bytes", (int)bytesread );
            handleEvent( ref event );
            return true;
        }

        critical( "Unsupported IOCondition %u", (int)condition );
        return true;
    }

    protected static void handleEvent( ref Linux.RfKillEvent event )
    {
        message( "got rfkill event: %u, %u, %u, %u, %u", event.idx, event.type, event.op, event.soft, event.hard );
        switch ( event.op )
        {
            case Linux.RfKillOp.ADD:
                instances.insert( (int)event.idx, new Kernel26.RfKillPowerControl( event.idx, event.type, (bool)event.soft, (bool)event.hard ) );
                break;
            case Linux.RfKillOp.DEL:
                instances.remove( (int)event.idx );
                break;
            default:
                critical( "unknown rfkill op %u; ignoring", event.op );
                break;
        }
    }

    public bool getPower()
    {
        return false;
    }

    public void setPower( bool on )
    {
    }

    //
    // DBUS API (org.freesmartphone.Device.PowerControl)
    //
    public async bool get_power() throws DBus.Error
    {
        return getPower();
    }

    public async void set_power( bool on ) throws DBus.Error
    {
        setPower( on );
    }
}
} /* namespace */

internal HashTable<int,Kernel26.RfKillPowerControl> instances;
internal static string sysfs_root;
internal static string devfs_root;
internal weak FsoFramework.Subsystem subsystem;

internal static int fd;
internal static uint watch;
internal static IOChannel channel;

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem system ) throws Error
{
    subsystem = system;
    // grab devfs paths
    var config = FsoFramework.theMasterKeyFile();
    devfs_root = config.stringValue( "cornucopia", "devfs_root", "/dev" );

    fd = Posix.open( Path.build_filename( devfs_root, "rfkill" ), Posix.O_RDWR );
    if ( fd == -1 )
    {
        error( @"Can't open $devfs_root/rfkill: $(strerror(errno)); rfkill plugin will not be operating" );
        return "";
    }
    instances = new HashTable<int,Kernel26.RfKillPowerControl>( direct_hash, direct_equal );
    channel = new IOChannel.unix_new( fd );
    watch = channel.add_watch( IOCondition.IN | IOCondition.HUP, Kernel26.RfKillPowerControl.onActionFromRfKill );
    return "fsodevice.kernel26_rfkill";
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    debug( "fsodevice.kernel26_rfkill fso_register_function()" );
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
