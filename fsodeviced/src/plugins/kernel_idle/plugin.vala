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

    internal const string KERNEL_IDLE_PLUGIN_NAME = "fsodevice.kernel_idle";

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
        instance.logger.debug( "onState transitioning from s%d to s%d".printf( this.status, status ) );

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
            instance.logger.debug( "Timeout for s%d disabled, not falling into this state next.".printf( next ) );
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

    private const int KEY_RELEASE = 0;
    private const int KEY_PRESS = 1;
    private const int KEY_REPEAT = 2;

    private string[] states;

    static construct
    {
        buffer = new char[BUFFER_SIZE];
    }

    public IdleNotifier( FsoFramework.Subsystem subsystem, string sysfsnode )
    {
        this.subsystem = subsystem;
        this.sysfsnode = sysfsnode;

        Idle.add( onIdle );

            // FIXME: Reconsider using /org/freesmartphone/Device/Input instead of .../IdleNotifier
            subsystem.registerServiceName( FsoFramework.Device.ServiceDBusName );
            subsystem.registerServiceObject( FsoFramework.Device.ServiceDBusName,
                                            "%s/0".printf( FsoFramework.Device.IdleNotifierServicePath ),
                                            this );
    }

    public override string repr()
    {
        return "<%s>".printf( sysfsnode );
    }

    private string _cleanBuffer( int length )
    {
        // work around bug in dbus(-glib?) which crashes when marshalling \xae which is the (C) symbol
        for ( int i = 0; i < length; ++i )
        {
            if ( buffer[i] < 0 )
                buffer[i] = '?';
        }
        return (string)buffer;
    }

    private bool _inquireAndCheckForIgnore( int fd )
    {
        var ignore = false;

        var length = Posix.ioctl( fd, Linux26.Input.EVIOCGNAME( BUFFER_SIZE ), buffer );
        if ( length > 0 )
        {
            var product = _cleanBuffer( length );
            foreach ( var i in ignoreById )
            {
                if ( i in product )
                {
                    ignore = true;
                }
            }
        }
        length = Posix.ioctl( fd, Linux26.Input.EVIOCGPHYS( BUFFER_SIZE ), buffer );
        if ( length > 0 )
        {
            var phys = _cleanBuffer( length );
            foreach ( var p in ignoreByPhys )
            {
                if ( p in phys )
                {
                    ignore = true;
                }
            }
        }
        return ignore;
    }

    public void onResourceChanged( FsoDevice.AbstractSimpleResource r, bool on )
    {
        if ( r is CpuResource )
        {
            logger.debug( "CPU resource changed status to %s".printf( on.to_string() ) );
            if (on)
            {
                // prohibit sending of suspend
                idlestatus.timeouts[FreeSmartphone.Device.IdleState.SUSPEND] = -1;
            }
            else
            {
                // allow sending of suspend
                idlestatus.timeouts[FreeSmartphone.Device.IdleState.SUSPEND] = config.intValue( KERNEL_IDLE_PLUGIN_NAME, states[FreeSmartphone.Device.IdleState.SUSPEND], 20 );
                // relaunch timer, if necessary
                if ( idlestatus.status == FreeSmartphone.Device.IdleState.LOCK )
                    idlestatus.onState( FreeSmartphone.Device.IdleState.LOCK );
            }
        }

        if ( r is DisplayResource )
        {
            logger.debug( "Display resource changed status to %s".printf( on.to_string() ) );
            if (on)
            {
                // prohibit sending of idle_dim (and later)
                idlestatus.timeouts[FreeSmartphone.Device.IdleState.IDLE_DIM] = -1;
                // relaunch timer, if necessary
                if ( (int)idlestatus.status > (int)FreeSmartphone.Device.IdleState.IDLE )
                    idlestatus.onState( FreeSmartphone.Device.IdleState.IDLE );
            }
            else
            {
                // allow sending of idle_dim (and later)
                idlestatus.timeouts[FreeSmartphone.Device.IdleState.IDLE_DIM] = config.intValue( KERNEL_IDLE_PLUGIN_NAME, states[FreeSmartphone.Device.IdleState.IDLE_DIM], 10 );
                // relaunch timer, if necessary
                if ( idlestatus.status == FreeSmartphone.Device.IdleState.IDLE )
                    idlestatus.onState( FreeSmartphone.Device.IdleState.IDLE );
            }
        }

    }

    public void resetTimeouts()
    {
        states = { "busy", "idle", "idle_dim", "idle_prelock", "lock", "suspend" };
        for ( int i = 0; i < states.length; ++i )
        {
            idlestatus.timeouts[i] = config.intValue( KERNEL_IDLE_PLUGIN_NAME, states[i], idlestatus.timeouts[i] );
        }
    }

    public bool onIdle()
    {
        idlestatus = new IdleStatus();
        idlestatus.onState( FreeSmartphone.Device.IdleState.AWAKE );

        resetTimeouts();
        syncNodesToWatch();
        registerInputWatches();

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
                {
                    logger.warning( "Could not open %s: %s (ignoring)".printf( entry, Posix.strerror( Posix.errno ) ) );
                }
                else if ( _inquireAndCheckForIgnore( fd ) )
                {
                    logger.info( "Skipping %s as instructed by configuration.".printf( entry ) );
                    Posix.close( fd );
                }
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

    private void _handleInputEvent( ref Linux26.Input.Event ev )
    {
        idlestatus.onState( FreeSmartphone.Device.IdleState.BUSY );
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
        var dict = new GLib.HashTable<string,int>( str_hash, str_equal );

        for ( int i = 0; i < states.length; ++i )
        {
            dict.insert( states[i], config.intValue( KERNEL_IDLE_PLUGIN_NAME, states[i], idlestatus.timeouts[i] ) );
        }
        return dict;
    }

    public void set_state( FreeSmartphone.Device.IdleState status ) throws DBus.Error
    {
        idlestatus.onState( status );
    }

    public void set_timeout( FreeSmartphone.Device.IdleState status, int timeout ) throws DBus.Error
    {
        idlestatus.timeouts[status] = timeout;
    }

}

/**
 * Implementation of org.freesmartphone.Resource for the Display Resource
 **/
class DisplayResource : FsoDevice.AbstractSimpleResource
{
    internal bool on;

    public DisplayResource( FsoFramework.Subsystem subsystem )
    {
        base( "Display", subsystem );
    }

    public override void _enable()
    {
        if (on)
            return;
        logger.debug( "enabling..." );
        instance.onResourceChanged( this, true );
        on = true;
    }

    public override void _disable()
    {
        if (!on)
            return;
        logger.debug( "disabling..." );
        instance.onResourceChanged( this, false );
        on = false;
    }
}


/**
 * Implementation of org.freesmartphone.Resource for the CPU Resource
 **/
class CpuResource : FsoDevice.AbstractSimpleResource
{
    internal bool on;

    public CpuResource( FsoFramework.Subsystem subsystem )
    {
        base( "CPU", subsystem );
    }

    public override void _enable()
    {
        if (on)
            return;
        logger.debug( "enabling..." );
        instance.onResourceChanged( this, true );
        on = true;
    }

    public override void _disable()
    {
        if (!on)
            return;
        logger.debug( "disabling..." );
        instance.onResourceChanged( this, false );
        on = false;
    }
}

} /* namespace */

internal static string dev_root;
internal static string dev_input;
internal Kernel.IdleNotifier instance;
internal Kernel.CpuResource cpu;
internal Kernel.DisplayResource display;
internal string[] ignoreById;
internal string[] ignoreByPhys;

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    // grab paths
    var config = FsoFramework.theMasterKeyFile();
    dev_root = config.stringValue( "cornucopia", "dev_root", "/dev" );
    dev_input = "%s/input".printf( dev_root );

    // grab entry for ignore lists
    ignoreById = config.stringListValue( Kernel.KERNEL_IDLE_PLUGIN_NAME, "ignore_by_id", new string[] {} );
    ignoreByPhys = config.stringListValue( Kernel.KERNEL_IDLE_PLUGIN_NAME, "ignore_by_path", new string[] {} );

    // create one and only instance
    instance = new Kernel.IdleNotifier( subsystem, dev_input );

    // create idle-notifier-aware resources
    cpu = new Kernel.CpuResource( subsystem );
    display = new Kernel.DisplayResource( subsystem );

    return Kernel.KERNEL_IDLE_PLUGIN_NAME;
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