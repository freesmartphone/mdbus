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

/*
[Compact]
public class EventStatus
{
    public EventStatus( string name, bool reportheld )
    {
        this.name = name;
        this.reportheld = reportheld;
        pressed = false;
        timeout = 0;
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
*/


/**
 * Implementation of org.freesmartphone.Device.IdleNotifier for Kernel Input Devices
 **/

class IdleNotifier : FreeSmartphone.Device.IdleNotifier, FsoFramework.AbstractObject
{
    private FsoFramework.Subsystem subsystem;
    private string sysfsnode;
    private IOChannel[] channels;

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

        _registerInputWatches();
        //_parseConfig();

        logger.info( "created new IdleNotifier." );
    }

    private void _registerInputWatches()
    {
        channels = new IOChannel[] {};
        /*
        foreach ( var input in instances )
        {
            var channel = new IOChannel.unix_new( input.fd );
            channel.add_watch( IOCondition.IN, onInputEvent );
            channels += channel;
        }
        /*
            // scan sysfs path for rtcs
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
        */

    }

    private void _parseConfig()
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

        if ( ev.type != Linux26.Input.EV_SYN )
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