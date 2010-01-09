/**
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
            logger.info( "Created new InputDevice object: '%s' @ '%s' w/ '%s'".printf( product, phys, caps ) );
        }
        else
            logger.info( "Skipping as per configuration: '%s' @ '%s' w/ '%s'".printf( product, phys, caps ) );
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

    private bool _inquireAndCheckForIgnore()
    {
        var ignore = false;

        fd = Posix.open( sysfsnode, Posix.O_RDONLY );
        if ( fd == -1 )
            logger.warning( "Can't open %s (%s). Full input device control not available.".printf( sysfsnode, Posix.strerror( Posix.errno ) ) );
        else
        {
            var length = Posix.ioctl( fd, Linux.Input.EVIOCGNAME( BUFFER_SIZE ), buffer );
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
            length = Posix.ioctl( fd, Linux.Input.EVIOCGPHYS( BUFFER_SIZE ), buffer );
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
            if ( Posix.ioctl( fd, Linux.Input.EVIOCGBIT( 0, Linux.Input.EV_MAX ), &b ) < 0 )
            {
                logger.error( "Can't inquire input device capabilities: %s".printf( strerror( errno ) ) );
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

            uint typelength = Linux.Input.KEY_MAX / 8 + 1;
            keystate = new uint8[typelength];
            if ( Posix.ioctl( fd, Linux.Input.EVIOCGKEY( typelength ), keystate ) < 0 )
            {
                logger.error( "Can't inquire input device key status: %s".printf( strerror( errno ) ) );
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
    public EventStatus( string name, bool reportheld )
    {
        this.name = name;
        this.reportheld = reportheld;
        pressed = false;
        timeout = 0;
        //message( "event status for %s (held %d) created", name, (int)reportheld );
    }

    ~EventStatus()
    {
        //message( "event status for %s (held %d) destroyed", name, (int)reportheld );
    }

    public bool pressed;
    public bool reportheld;
    public TimeVal timestamp;
    public uint timeout;
    public string name;

    public uint age()
    {
        var now = TimeVal();
        var diff = ( now.tv_sec - timestamp.tv_sec ) * 1000000 + ( now.tv_usec - timestamp.tv_usec );
        return (uint) diff / 1000000;
    }

    public bool onTimeout()
    {
        aggregate.event( name, FreeSmartphone.Device.InputState.HELD, (int) age() ); // DBUS SIGNAL
        return true;
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

    public AggregateInputDevice( FsoFramework.Subsystem subsystem, string sysfsnode )
    {
        this.subsystem = subsystem;
        this.sysfsnode = sysfsnode;

        _registerInputWatches();

        keys = new HashMap<int,EventStatus>( direct_hash, direct_equal, direct_equal );
        switches = new HashMap<int,EventStatus>( direct_hash, direct_equal, direct_equal );

        _parseConfig();

        subsystem.registerServiceName( FsoFramework.Device.ServiceDBusName );
        subsystem.registerServiceObject( FsoFramework.Device.ServiceDBusName,
                                         FsoFramework.Device.InputServicePath,
                                         this );
        logger.info( "Created new AggregateInputDevice object." );

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
                        logger.info( "Sending coldplug input notification for bit %s:%d".printf( input.name, i ) );
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
                logger.warning( "config option %s has not 4 elements. Ignoring.".printf( entry ) );
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
                default:
                    logger.warning( "config option %s has unknown type element. Ignoring".printf( entry ) );
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
            default:
                break;
        }

        if ( table == null )
            return;

        EventStatus es = table[ev.code];
        if ( es == null )
            return;

        switch ( ev.value )
        {
            case ( KEY_PRESS ):
                es.timestamp.tv_sec = ev.time.tv_sec;
                es.timestamp.tv_usec = ev.time.tv_usec;
                es.pressed = true;

                //logger.debug( "%s pressed".printf( es.name ) );

                if ( es.reportheld )
                {
                    es.timeout = Timeout.add( 1050, es.onTimeout );
                }
                this.event( es.name, FreeSmartphone.Device.InputState.PRESSED, 0 ); // DBUS SIGNAL
                break;

            case ( KEY_RELEASE ):
                //logger.debug( "%s released".printf( es.name ) );
                if ( !es.pressed )
                {
                    logger.warning( "received release event before pressed event!?" );
                    this.event( es.name, FreeSmartphone.Device.InputState.RELEASED, 0 ); // DBUS SIGNAL
                }
                else
                {
                    es.pressed = false;
                    if ( es.timeout > 0 )
                    {
                        Source.remove( es.timeout );
                    }
                    this.event( es.name, FreeSmartphone.Device.InputState.RELEASED, (int) es.age() ); // DBUS SIGNAL
                }
                break;

            case ( KEY_REPEAT ):
                //logger.debug( "%s autorepeat (ignoring)".printf( es.name ) );
                break;

            default:
                logger.debug( "%s unknown action %d; please report.".printf( es.name, ev.value ) );
                break;
        }
    }

    public override string repr()
    {
        return "<%s>".printf( sysfsnode );
    }

    public bool onInputEvent( IOChannel source, IOCondition condition )
    {
        Linux.Input.Event ev = {};
        var bytesread = Posix.read( source.unix_get_fd(), &ev, sizeof(Linux.Input.Event) );
        if ( bytesread == 0 )
        {
            logger.warning( "could not read from input device fd %d.".printf( source.unix_get_fd() ) );
            return false;
        }

        if ( ev.type != Linux.Input.EV_SYN )
        {
            logger.debug( "input ev %d, %d, %d, %d".printf( source.unix_get_fd(), ev.type, ev.code, ev.value ) );
            _handleInputEvent( ref ev );
        }

        return true;
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
    debug( "fsodevice.kernel_input fso_register_function()" );
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
