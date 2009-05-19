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

namespace Kernel
{
    internal char[] buffer;
    internal const uint BUFFER_SIZE = 512;

    internal const string CONFIG_SECTION = "fsodevice.kernel_idle";

/**
 * Helper class
 **/
[Compact]
public class IdleStatus
{
    public int[] timeouts;
    public FreeSmartphone.Device.IdleState status = FreeSmartphone.Device.IdleState.AWAKE;
    public uint watch;

    public IdleStatus()
    {
        timeouts = new int[] {
             0, /* awake to busy */
             2, /* busy to idle */
            10, /* idle to idle_dim */
            20, /* idle_dim to idle_prelock */
             2, /* idle_prelock to lock */
            20, /* lock to suspend */
            -1  /* suspend to awake */
        };
    }

    private FreeSmartphone.Device.IdleState nextState()
    {
        if ( status == FreeSmartphone.Device.IdleState.AWAKE )
            return 0;
        else
            return (FreeSmartphone.Device.IdleState) ( (int)status + 1 );
    }

    public void onState( FreeSmartphone.Device.IdleState status )
    {
        //debug( "onState transitioning from %d to %d", this.status, status );

        if ( watch > 0 )
            Source.remove( watch );

        if ( this.status != status )
        {
            this.status = status;
            instance.state( this.status ); // DBUS SIGNAL
        }

        var next = nextState();
        if ( timeouts[next] > 0 )
        {
            watch = Timeout.add_seconds( timeouts[next], onTimeout );
        }
        else if ( timeouts[next] == 0 )
        {
            onState( nextState() );
        }
        else
        {
            debug( "Timeout for %d disabled, not falling into this state next.".printf( next ) );
        }
    }

    public bool onTimeout()
    {
        watch = 0;
        onState( nextState() );
        return false;
    }
}

/**
 * Implementation of org.freesmartphone.Device.IdleNotifier for Kernel Input Devices
 **/
class IdleNotifier : FreeSmartphone.Device.IdleNotifier, FsoFramework.AbstractObject
{
    private FsoFramework.Subsystem subsystem;
    private string sysfsnode;
    private int[] fds;
    private IOChannel[] channels;

    private IdleStatus idlestatus;

//     private HashTable<int,EventStatus> keys;
//     private HashTable<int,EventStatus> switches;

    private const int KEY_RELEASE = 0;
    private const int KEY_PRESS = 1;
    private const int KEY_REPEAT = 2;

    public IdleNotifier( FsoFramework.Subsystem subsystem, string sysfsnode )
    {
        this.subsystem = subsystem;
        this.sysfsnode = sysfsnode;

        subsystem.registerServiceName( FsoFramework.Device.ServiceDBusName );
        subsystem.registerServiceObject( FsoFramework.Device.ServiceDBusName,
                                         FsoFramework.Device.InputServicePath,
                                         this );

        syncNodesToWatch();
        registerInputWatches();

        Idle.add( onIdle );
        logger.info( "created new IdleNotifier." );
    }

    public bool onIdle()
    {
        idlestatus = new IdleStatus();
        idlestatus.onState( FreeSmartphone.Device.IdleState.AWAKE );
        return false;
    }


    private void syncNodesToWatch()
    {
        fds = new int[] {};
        // scan sysfs path
        var dir = Dir.open( sysfsnode );
        var entry = dir.read_name();
        while ( entry != null )
        {
            if ( entry.has_prefix( "event" ) )
            {
                // try to open
                var fd = Posix.open( Path.build_filename( dev_input, entry ), Posix.O_RDONLY );
                if ( fd == -1 )
                    logger.warning( "could not open %s: %s (ignoring)".printf( entry, Posix.strerror( Posix.errno ) ) );
                else
                    fds += fd;
            }
            entry = dir.read_name();
        }
    }

    private void registerInputWatches()
    {
        channels = new IOChannel[] {};

        foreach ( var fd in fds )
        {
            var channel = new IOChannel.unix_new( fd );
            channel.add_watch( IOCondition.IN, onInputEvent );
            channels += channel;
        }
    }

    private void parseConfig()
    {
        /*
        var entries = config.keysWithPrefix( CONFIG_SECTION, "report" );
        foreach ( var entry in entries )
        {
            var value = config.stringValue( CONFIG_SECTION, entry );
            message( "got value '%s'", value );
            var values = value.split( "," );
            if ( values.length != 4 )
            {
                logger.warning( "config option %s has not 4 elements. Ignoring.".printf( entry ) );
                continue;
            }
            var name = values[0];
            var type = values[1].down();
            int code = values[2].to_int();
            var reportheld = values[3] == "1";

            HashTable<int,EventStatus> table;

            switch ( type )
            {
                case "key":
                    if ( keys == null )
                        keys = new HashTable<int,string>( direct_hash, direct_equal );
                    table = keys;
                    break;
                case "switch":
                    if ( switches == null )
                        switches = new HashTable<int,string>( direct_hash, direct_equal );
                    table = switches;
                    break;
                default:
                    logger.warning( "config option %s has unknown type element. Ignoring".printf( entry ) );
                    continue;
            }

            table.insert( code, new EventStatus( name, reportheld ) );
        }
        */
    }

    private void _handleInputEvent( ref Linux26.Input.Event ev )
    {
        idlestatus.onState( FreeSmartphone.Device.IdleState.BUSY );
    }

    public override string repr()
    {
        return "<FsoFramework.Device.IdleNotifier @ %s>".printf( sysfsnode );
    }

    public bool onInputEvent( IOChannel source, IOCondition condition )
    {
        Linux26.Input.Event ev = {};
        var bytesread = Posix.read( source.unix_get_fd(), &ev, sizeof(Linux26.Input.Event) );
        if ( bytesread == 0 )
        {
            logger.warning( "could not read from input device fd %d.".printf( source.unix_get_fd() ) );
            return false;
        }

        // only honor keys and buttons for now
        if ( ev.type == Linux26.Input.EV_KEY )
        {
            //logger.debug( "input ev %d, %d, %d, %d".printf( source.unix_get_fd(), ev.type, ev.code, ev.value ) );
            _handleInputEvent( ref ev );
        }

        return true;
    }

    //
    // DBUS API
    //
    public FreeSmartphone.Device.IdleState get_state() throws DBus.Error
    {
        return 0;
    }

    public GLib.HashTable<string,int> get_timeouts() throws DBus.Error
    {
        return new GLib.HashTable<string,int>( str_hash, str_equal );
    }

    public void set_state (FreeSmartphone.Device.IdleState status) throws DBus.Error
    {
    }

    public void set_timeout (string state, int timeout) throws DBus.Error
    {
    }

}

} /* namespace */

internal static string dev_root;
internal static string dev_input;
internal Kernel.IdleNotifier instance;

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
    dev_root = config.stringValue( "cornucopia", "dev_root", "/dev" );
    dev_input = "%s/input".printf( dev_root );

    instance = new Kernel.IdleNotifier( subsystem, dev_input );

    return "fsodevice.kernel_idle";
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    debug( "input fso_register_function()" );
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