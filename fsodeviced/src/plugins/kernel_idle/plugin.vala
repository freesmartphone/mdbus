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
        if ( watch > 0 )
        {
            Source.remove( watch );
        }

        if ( this.status != status )
        {
            assert( instance.logger.debug( @"onState transitioning from $(this.status) to $(status)" ) );
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
            assert( instance.logger.debug( @"Timeout for $(next) disabled, not falling into this state." ) );
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

    private FreeSmartphone.Device.IdleState displayResourcePreventState;

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

        var display_resource_allows_dim = config.boolValue( KERNEL_IDLE_PLUGIN_NAME, "display_resource_allows_dim", false );
        displayResourcePreventState = display_resource_allows_dim ? FreeSmartphone.Device.IdleState.IDLE_PRELOCK : FreeSmartphone.Device.IdleState.IDLE_DIM;
    }

    public override string repr()
    {
        return @"<$sysfsnode>";
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

        var length = Linux.ioctl( fd, Linux.Input.EVIOCGNAME( BUFFER_SIZE ), buffer );
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
        length = Linux.ioctl( fd, Linux.Input.EVIOCGPHYS( BUFFER_SIZE ), buffer );
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

    public void onResourceChanged( FsoFramework.AbstractDBusResource r, bool on )
    {
        if ( r is CpuResource )
        {
            assert( logger.debug( @"CPU resource changed status to $on" ) );
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
            assert( logger.debug( @"Display resource changed status to $on" ) );
            if (on)
            {
                // prohibit sending of idle_dim (and later)
                idlestatus.timeouts[displayResourcePreventState] = -1;
                // relaunch timer, if necessary
                if ( (int)idlestatus.status > (int)FreeSmartphone.Device.IdleState.IDLE )
                    idlestatus.onState( FreeSmartphone.Device.IdleState.IDLE );
            }
            else
            {
                // allow sending of idle_dim (and later)
                idlestatus.timeouts[displayResourcePreventState] = config.intValue( KERNEL_IDLE_PLUGIN_NAME, states[displayResourcePreventState], 10 );
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

        FsoFramework.BaseKObjectNotifier.addMatch( "add", "input", onInputNotification );
        FsoFramework.BaseKObjectNotifier.addMatch( "remove", "input", onInputNotification );

        return false;
    }

    public void onInputNotification( HashTable<string,string> properties )
    {
        var devpath = properties.lookup( "DEVPATH" );
        if ( devpath != null && "event" in devpath )
        {
            resetTimeouts();
            syncNodesToWatch();
            registerInputWatches();
        }
    }

    private void syncNodesToWatch()
    {
        // close, if already open
        if ( fds != null )
        {
            foreach ( var fd in fds )
            {
                Posix.close( fd );
            }
        }

        fds = new int[] {};
        Dir dir;
        // scan sysfs path
        try
        {
            dir = Dir.open( sysfsnode );
        }
        catch ( GLib.Error e )
        {
            logger.error( @"Can't open $sysfsnode ($(e.message)); idle notifier will not work" );
            return;
        }
        var entry = dir.read_name();
        while ( entry != null )
        {
            if ( entry.has_prefix( "event" ) )
            {
                // try to open
                var fd = Posix.open( Path.build_filename( dev_input, entry ), Posix.O_RDONLY );
                if ( fd == -1 )
                {
                    logger.warning( @"Could not open $entry: $(strerror(errno)) (ignoring)" );
                }
                else if ( _inquireAndCheckForIgnore( fd ) )
                {
                    logger.info( @"Skipping $entry as instructed by configuration" );
                    Posix.close( fd );
                }
                else
                {
                    fds += fd;
                }
            }
            entry = dir.read_name();
        }
    }

    private void registerInputWatches()
    {
        // should auto-unref and close channels
        channels = new IOChannel[] {};

        foreach ( var fd in fds )
        {
            var channel = new IOChannel.unix_new( fd );
            channel.set_close_on_unref( true );
            channel.add_watch( IOCondition.IN, onInputEvent );
            channels += channel;
        }
    }

    private void _handleInputEvent( ref Linux.Input.Event ev )
    {
        idlestatus.onState( FreeSmartphone.Device.IdleState.BUSY );
    }

    public bool onInputEvent( IOChannel source, IOCondition condition )
    {
        Linux.Input.Event ev = {};
        var bytesread = Posix.read( source.unix_get_fd(), &ev, sizeof(Linux.Input.Event) );
        if ( bytesread == 0 )
        {
            logger.warning( @"Could not read from input device fd $(source.unix_get_fd())" );
            return false;
        }

#if DEBUG
        assert( logger.debug( @"Input event (fd$(source.unix_get_fd())): $(ev.type), $(ev.code), $(ev.value)" ) );
#endif
        _handleInputEvent( ref ev );

        return true;
    }

    //
    // FreeSnmartphone.Device.IdleNotifier (DBUS API)
    //
    public async FreeSmartphone.Device.IdleState get_state() throws DBusError, IOError
    {
        return 0;
    }

    public async GLib.HashTable<string,int> get_timeouts() throws DBusError, IOError
    {
        var dict = new GLib.HashTable<string,int>( str_hash, str_equal );

        for ( int i = 0; i < states.length; ++i )
        {
            dict.insert( states[i], config.intValue( KERNEL_IDLE_PLUGIN_NAME, states[i], idlestatus.timeouts[i] ) );
        }
        return dict;
    }

    public async void set_state( FreeSmartphone.Device.IdleState status ) throws DBusError, IOError
    {
        idlestatus.onState( status );
    }

    public async void set_timeout( FreeSmartphone.Device.IdleState status, int timeout ) throws DBusError, IOError
    {
        config.write( KERNEL_IDLE_PLUGIN_NAME, states[status], timeout );
        idlestatus.timeouts[status] = timeout;
    }

}

/**
 * Implementation of org.freesmartphone.Resource for the Display Resource
 **/
class DisplayResource : FsoFramework.AbstractDBusResource
{
    internal bool on;

    public DisplayResource( FsoFramework.Subsystem subsystem )
    {
        base( "Display", subsystem );
    }

    public override async void enableResource()
    {
        if (on)
            return;
        assert( logger.debug( "Enabling..." ) );
        instance.onResourceChanged( this, true );
        on = true;
    }

    public override async void disableResource()
    {
        if (!on)
            return;
        assert( logger.debug( "Disabling..." ) );
        instance.onResourceChanged( this, false );
        on = false;
    }

    public override async void suspendResource()
    {
    }

    public override async void resumeResource()
    {
    }
}


/**
 * Implementation of org.freesmartphone.Resource for the CPU Resource
 **/
class CpuResource : FsoFramework.AbstractDBusResource
{
    internal bool on;

    public CpuResource( FsoFramework.Subsystem subsystem )
    {
        base( "CPU", subsystem );
    }

    public override async void enableResource()
    {
        if (on)
            return;
        assert( logger.debug( "Enabling..." ) );
        instance.onResourceChanged( this, true );
        on = true;
    }

    public override async void disableResource()
    {
        if (!on)
            return;
        assert( logger.debug( "Disabling..." ) );
        instance.onResourceChanged( this, false );
        on = false;
    }

    public override async void suspendResource()
    {
    }

    public override async void resumeResource()
    {
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
    var config = FsoFramework.theConfig;
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
    FsoFramework.theLogger.debug( "fsodevice.kernel_idle fso_register_function()" );
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
