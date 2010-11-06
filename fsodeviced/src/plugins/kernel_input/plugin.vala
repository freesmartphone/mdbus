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
using Gee;

namespace Kernel
{
    internal char[] buffer;
    internal const uint BUFFER_SIZE = 512;

    internal const string KERNEL_INPUT_PLUGIN_NAME = "fsodevice.kernel_input";

    internal const int KEY_RELEASE = 0;
    internal const int KEY_PRESS = 1;
    internal const int KEY_REPEAT = 2;

/**
 * Implementation of org.freesmartphone.Device.Input for the Kernel Input Device
 **/
class InputDevice : FreeSmartphone.Device.Input, FsoFramework.AbstractObject
{
    FsoFramework.Subsystem subsystem;

    private string sysfsnode;
    private static uint counter;
    private static uint typelength;

    // internal, so it can be accessable from aggregate input device
    internal string name;
    internal string product = "<Unknown Product>";
    internal string phys = "<Unknown Path>";
    internal string caps = "<Unknown Caps>";
    internal int fd = -1;
    internal uint8[] keystate;

    static construct
    {
        buffer = new char[BUFFER_SIZE];
        typelength = Linux.Input.KEY_MAX / 8 + 1;
    }

    construct
    {
        keystate = new uint8[typelength];
    }

    public InputDevice( FsoFramework.Subsystem subsystem, string sysfsnode )
    {
        this.subsystem = subsystem;
        this.sysfsnode = sysfsnode;
        this.name = Path.get_basename( sysfsnode );

        if ( !_inquireAndCheckForIgnore() )
        {
            subsystem.registerServiceName( FsoFramework.Device.ServiceDBusName );
            subsystem.registerServiceObject( FsoFramework.Device.ServiceDBusName,
                                             "%s/%u".printf( FsoFramework.Device.InputServicePath, counter++ ),
                                                     this );
            logger.info( @"Created new InputDevice object: $product @ $phys w/ $caps" );
        }
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

    private bool _inquireAndCheckForIgnore()
    {
        var ignore = false;

        fd = Posix.open( sysfsnode, Posix.O_RDONLY );
        if ( fd == -1 )
        {
            logger.warning( @"Can't open $sysfsnode $(strerror(errno)). Input device will not available." );
            ignore = true;
        }
        else
        {
            var length = Linux.ioctl( fd, Linux.Input.EVIOCGNAME( BUFFER_SIZE ), buffer );
            if ( length > 0 )
            {
                product = _cleanBuffer( length );
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
                phys = _cleanBuffer( length );
                foreach ( var p in ignoreByPhys )
                {
                    if ( p in phys )
                    {
                        ignore = true;
                    }
                }
            }
            ushort b = 0;
            if ( Linux.ioctl( fd, Linux.Input.EVIOCGBIT( 0, Linux.Input.EV_MAX ), &b ) < 0 )
            {
                logger.error( @"Can't inquire input device capabilities: $(strerror(errno))" );
            }
            else
            {
                caps = "";
                if ( ( b & ( 1 << Linux.Input.EV_SYN ) ) > 0 )
                    caps += " SYN";
                if ( ( b & ( 1 << Linux.Input.EV_KEY ) ) > 0 )
                    caps += " KEY";
                if ( ( b & ( 1 << Linux.Input.EV_REL ) ) > 0 )
                    caps += " REL";
                if ( ( b & ( 1 << Linux.Input.EV_ABS ) ) > 0 )
                    caps += " ABS";
                if ( ( b & ( 1 << Linux.Input.EV_MSC ) ) > 0 )
                    caps += " MSC";
                if ( ( b & ( 1 << Linux.Input.EV_SW ) ) > 0 )
                    caps += " SW";
                if ( ( b & ( 1 << Linux.Input.EV_LED ) ) > 0 )
                    caps += " LED";
                if ( ( b & ( 1 << Linux.Input.EV_SND ) ) > 0 )
                    caps += " SND";
                if ( ( b & ( 1 << Linux.Input.EV_REP ) ) > 0 )
                    caps += " REP";
                if ( ( b & ( 1 << Linux.Input.EV_FF ) ) > 0 )
                    caps += " FF";
                if ( ( b & ( 1 << Linux.Input.EV_PWR ) ) > 0 )
                    caps += " PWR";
                if ( ( b & ( 1 << Linux.Input.EV_FF_STATUS ) ) > 0 )
                    caps += " FF_STATUS";
            }
            caps = caps.strip();

            if ( Linux.ioctl( fd, Linux.Input.EVIOCGKEY( typelength ), keystate ) < 0 )
            {
                logger.error( @"Can't inquire input device key status: $(strerror(errno))" );
            }
        }
        if ( ignore && fd != -1 )
        {
            Posix.close( fd );
            fd = -1;
        }
        return ignore;
    }

    public bool onIdle()
    {
        // trigger coldplug change notification
        FsoFramework.FileHandling.write( "change", "%s/uevent".printf( sysfsnode ) );
        return false; // mainloop: don't call again
    }

    //
    // FsoFramework.Device.Input (DBUS)
    //
    public async string get_name() throws DBus.Error
    {
        return name;
    }

    public async string get_id() throws DBus.Error
    {
        return product;
    }

    public async string get_phys() throws DBus.Error
    {
        return phys;
    }

    public async string get_capabilities() throws DBus.Error
    {
        return caps;
    }
}

/**
 * Helper class
 **/
public class EventStatus
{
    private bool pressed;
    private bool reportheld;
    private TimeVal timestamp;
    private uint timeout;
    private string name;

    private uint age()
    {
        var now = TimeVal();
        var diff = ( now.tv_sec - timestamp.tv_sec ) * 1000000 + ( now.tv_usec - timestamp.tv_usec );
        return (uint) diff / 1000000;
    }

    private bool onTimeout()
    {
        aggregate.event( name, FreeSmartphone.Device.InputState.HELD, (int) age() ); // DBUS SIGNAL
        return true;
    }

    ~EventStatus()
    {
#if DEBUG
        debug( @"EventStatus for $name (held $reportheld) destroyed" );
#endif
    }

    //
    // public API
    //

    public EventStatus( string name, bool reportheld )
    {
        this.name = name;
        this.reportheld = reportheld;
        pressed = false;
        timeout = 0;
#if DEBUG
        debug( @"EventStatus for $name (held $reportheld) created" );
#endif
    }

    public void handleRelative( Linux.Input.Event ev )
    {
        var axis = ev.code;
        var offset = ev.value;
        aggregate.directional_event( name, axis, offset );
    }

    public void handle( Linux.Input.Event ev )
    {
        if ( ev.type == Linux.Input.EV_REL )
        {
            handleRelative( ev );
            return;
        }

        switch ( ev.value )
        {
            case ( KEY_PRESS ):
                timestamp = TimeVal();
                pressed = true;
#if DEBUG
                aggregate.logger.debug( @"$name pressed" );
#endif
                if ( reportheld )
                {
                    timeout = Timeout.add( 1050, onTimeout );
                }
                aggregate.event( name, FreeSmartphone.Device.InputState.PRESSED, 0 ); // DBUS SIGNAL
                break;

            case ( KEY_RELEASE ):
#if DEBUG
                aggregate.logger.debug( @"$name released" );
#endif
                if ( !pressed )
                {
                    aggregate.logger.warning( "Received release event before pressed event!?" );
                    aggregate.event( name, FreeSmartphone.Device.InputState.RELEASED, 0 ); // DBUS SIGNAL
                }
                else
                {
                    pressed = false;
                    if ( timeout > 0 )
                    {
                        Source.remove( timeout );
                    }
                    aggregate.event( name, FreeSmartphone.Device.InputState.RELEASED, (int) age() ); // DBUS SIGNAL
                }
                break;

            case ( KEY_REPEAT ):
#if DEBUG
                aggregate.logger.debug( @"$name autorepeat (ignoring)" );
#endif
                break;

            default:
#if DEBUG
                aggregate.logger.debug( @"$name unknown action $(ev.value); please report." );
#endif
                break;
        }
    }
}

/**
 * Implementation of org.freesmartphone.Device.InputDevice as aggregated Kernel Input Device
 **/

class AggregateInputDevice : FreeSmartphone.Device.Input, FsoFramework.AbstractObject
{
    private FsoFramework.Subsystem subsystem;
    private string sysfsnode;
    private IOChannel[] channels;

    private HashMap<int,EventStatus> keys;
    private HashMap<int,EventStatus> switches;
    private HashMap<int,EventStatus> relatives;

    public AggregateInputDevice( FsoFramework.Subsystem subsystem, string sysfsnode )
    {
        this.subsystem = subsystem;
        this.sysfsnode = sysfsnode;

        _registerInputWatches();
        _hookToExternalModules();

        keys = new HashMap<int,EventStatus>( direct_hash, direct_equal, direct_equal );
        switches = new HashMap<int,EventStatus>( direct_hash, direct_equal, direct_equal );
        relatives = new HashMap<int,EventStatus>( direct_hash, direct_equal, direct_equal );

        _parseConfig();

        subsystem.registerServiceName( FsoFramework.Device.ServiceDBusName );
        subsystem.registerServiceObject( FsoFramework.Device.ServiceDBusName,
                                         FsoFramework.Device.InputServicePath,
                                         this );
        logger.info( "Created" );

        Idle.add( onIdle );
    }

    private void _registerInputWatches()
    {
        channels = new IOChannel[] {};
        foreach ( var input in instances )
        {
            if ( input.fd != -1 )
            {
                var channel = new IOChannel.unix_new( input.fd );
                channel.add_watch( IOCondition.IN, onInputEvent );
                channels += channel;
            }
        }
    }

    private void _hookToExternalModules()
    {
        foreach ( var object in subsystem.allObjectsWithPrefix( "/org/freesmartphone/Device/Input/" ) )
        {
            if ( object is FsoDevice.SignallingInputDevice )
            {
                logger.debug( "Found an auxilliary input object, connecting to signal" );
                ((FsoDevice.SignallingInputDevice) object ).receivedEvent.connect( _handleInputEvent );
            }
        }
    }

    private bool _testbit( uint bit, uint8[] field )
    {
        var boffset = bit / 8;
        var bmodulo = bit % 8;
        var mask = 1 << bmodulo;

        return ( ( field[boffset] & mask ) == mask );
    }

    private bool onIdle()
    {
        // coldplug
        foreach ( var input in instances )
        {
            if ( input.fd != 1 )
            {
                for ( int i = 0; i < Linux.Input.KEY_MAX; ++i )
                {
                    if ( _testbit( i, input.keystate ) )
                    {
                        logger.info( @"Sending coldplug input notification for bit $(input.name):$i" );
                        // need to do it both for switches and keys, since we differenciate between those two
                        var ev1 = Linux.Input.Event() { time = Posix.timeval() { tv_sec=0, tv_usec=0 }, type=(uint16)Linux.Input.EV_KEY, code=(uint16)i, value=KEY_PRESS };
                        _handleInputEvent( ref ev1 );
                        var ev2 = Linux.Input.Event() { time = Posix.timeval() { tv_sec=0, tv_usec=0 }, type=(uint16)Linux.Input.EV_SW, code=(uint16)i, value=KEY_PRESS };
                        _handleInputEvent( ref ev2 );
                    }
                }
            }
        }
        return false; // Don't call me again
    }

    private void _parseConfig()
    {
        var entries = config.keysWithPrefix( KERNEL_INPUT_PLUGIN_NAME, "report" );
        foreach ( var entry in entries )
        {
            var value = config.stringValue( KERNEL_INPUT_PLUGIN_NAME, entry );
            //message( "got value '%s'", value );
            var values = value.split( "," );
            if ( values.length != 4 )
            {
                logger.warning( @"Config option $entry has not 4 elements. Ignoring." );
                continue;
            }
            var name = values[0];
            var type = values[1].down();
            int code = values[2].to_int();
            var reportheld = values[3] == "1";

            switch ( type )
            {
                case "key":
                    keys[code] = new EventStatus( name, reportheld );
                    break;
                case "switch":
                    switches[code] = new EventStatus( name, reportheld );
                    break;
                case "relative":
                    relatives[code] = new EventStatus( name, reportheld );
                    break;
                default:
                    logger.warning( @"Config option $entry has unknown type element $type. Ignoring" );
                    continue;
            }
        }
    }

    private void _handleInputEvent( ref Linux.Input.Event ev )
    {
        HashMap<int,EventStatus> table = null;

        switch ( ev.type )
        {
            case Linux.Input.EV_KEY:
                table = keys;
                break;
            case Linux.Input.EV_SW:
                table = switches;
                break;
            case Linux.Input.EV_REL:
                table = relatives;
                break;
            default:
                break;
        }

        if ( table == null )
            return;

        EventStatus es = table[ev.code];
        if ( es == null )
            return;

        es.handle( ev );
    }

    public override string repr()
    {
        return @"<$sysfsnode>";
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

        if ( ev.type != Linux.Input.EV_SYN )
        {
#if DEBUG
            logger.debug( @"Input event (fd$(source.unix_get_fd())): $(ev.type), $(ev.code), $(ev.value)" );
#endif
            _handleInputEvent( ref ev );
        }

        return true; // mainloop: call us again next time
    }

    //
    // DBUS API
    //
    public async string get_name() throws DBus.Error
    {
        return dev_input;
    }

    public async string get_id() throws DBus.Error
    {
        return "aggregate";
    }

    public async string get_phys() throws DBus.Error
    {
        return "";
    }

    public async string get_capabilities() throws DBus.Error
    {
        return "none";
    }

}

} /* namespace */

internal static string dev_root;
internal static string dev_input;
internal GLib.List<Kernel.InputDevice> instances;
internal Kernel.AggregateInputDevice aggregate;
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
    // grab path from config
    var config = FsoFramework.theConfig;
    dev_root = config.stringValue( "cornucopia", "dev_root", "/dev" );
    dev_input = "%s/input".printf( dev_root );

    // grab entry for ignore lists
    ignoreById = config.stringListValue( Kernel.KERNEL_INPUT_PLUGIN_NAME, "ignore_by_id", new string[] {} );
    ignoreByPhys = config.stringListValue( Kernel.KERNEL_INPUT_PLUGIN_NAME, "ignore_by_path", new string[] {} );

    // scan path for nodes
    var dir = Dir.open( dev_input );
    var entry = dir.read_name();
    while ( entry != null )
    {
        if ( entry.has_prefix( "event" ) )
        {
            var filename = Path.build_filename( dev_input, entry );
            instances.append( new Kernel.InputDevice( subsystem, filename ) );
        }
        entry = dir.read_name();
    }

    // always create aggregated object
    aggregate = new Kernel.AggregateInputDevice( subsystem, dev_input );

    return Kernel.KERNEL_INPUT_PLUGIN_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsodevice.kernel_input fso_register_function()" );
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
