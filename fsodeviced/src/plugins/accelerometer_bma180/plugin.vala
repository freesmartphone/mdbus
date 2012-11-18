/*
 * Copyright (C) 2012 Rico Rommel <rico@bierrommel.de>
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

namespace Hardware {

    internal const string PLUGIN_NAME = "fsodevice.accelerometer_bma180";
    internal const string DEFAULT_EVENT_NODE = "/input/event1";

class AccelerometerBma180 : FsoDevice.BaseAccelerometer
{
    private string inputnode;


    internal int fd = -1;
    private IOChannel channel;
    private uint watch;
    private int[] axis;

    construct
    {
        logger.info( "Registering bma180 accelerometer" );
        // grab sysfs paths
        var devfs_root = config.stringValue( "cornucopia", "devfs_root", "/dev" );
        inputnode = devfs_root + config.stringValue( PLUGIN_NAME, "inputnode", DEFAULT_EVENT_NODE );


        axis = new int[3];
    }

    public override string repr()
    {
        return "<via %s>".printf( inputnode );
    }

    public override void start()
    {
        fd = Posix.open( inputnode, Posix.O_RDONLY );
        if ( fd == -1 )
        {
            logger.warning( @"Can't open $inputnode: $(strerror(errno)) Bma180 Accelerometer not available." );
            return;
        }
        channel = new IOChannel.unix_new( fd );
        watch = channel.add_watch( IOCondition.IN, onInputEvent );
    }

    public override void stop()
    {
        if ( watch > 0 )
        {
            Source.remove( watch );
        }
        channel = null;
        if ( fd != -1 )
        {
            Posix.close( fd );
        }
        fd = -1;
    }

    private void _handleInputEvent( ref Linux.Input.Event ev )
    {
        if ( ev.code > 2 )
        {
            logger.warning( "Invalid data from input device. axis > 2" );
            return;
        }

        axis[ev.code] = ev.value;
        this.accelerate( -1*axis[0], -1*axis[1], axis[2] );
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

        // we're only interested in the absolute axis values
        if ( ev.type == Linux.Input.EV_ABS )
        {
            assert( logger.debug( "input ev %d, %d, %d, %d".printf( source.unix_get_fd(), ev.type, ev.code, ev.value ) ) );
            _handleInputEvent( ref ev );
        }
#if DEBUG
        else
        {
            assert( logger.debug( "(ignoring non-ABS) input ev %d, %d, %d, %d".printf( source.unix_get_fd(), ev.type, ev.code, ev.value ) ) );
        }
#endif

        return true;
    }
}

} /* namespace Hardware */

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    return Hardware.PLUGIN_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsodevice.accelerometer_bma180 fso_register_function" );
}

// vim:ts=4:sw=4:expandtab
