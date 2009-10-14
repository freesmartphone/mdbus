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

using Gee;

namespace FsoGps { public FsoGps.Receiver theReceiver; }

public abstract interface FsoGps.Receiver : FsoFramework.AbstractObject
{
    public class Data : GLib.Object
    {
    }

    public enum Status
    {
        /** Initial state, Transport is closed **/
        CLOSED,
        /** Transport open, initialization commands are being sent **/
        INITIALIZING,
        /** Initialized, FIX status unknown **/
        ALIVE,
        /** Initialized, TIME is received **/
        ALIVE_TIME,
        /** Initialized, FIX is 2d **/
        ALIVE_FIX_2D,
        /** Initialized, FIX is 3d **/
        ALIVE_FIX_3D,
        /** Suspend commands are being sent **/
        SUSPENDING,
        /** Suspended **/
        SUSPENDED,
        /** Resume commands are being sent **/
        RESUMING,
        /* ALIVE */
    }

    // called by the channel upon creation
    public abstract void registerChannel( string name, FsoGps.Channel channel );
    public abstract bool open();
    public abstract void close();
    //FIXME: Should be FsoGps.Receiver.Status with Vala >= 0.7
    public abstract int status();

    public signal void signalStatusChanged( /* FsoGps.Receiver.Status */ int status );

    public abstract Data data();
    public abstract T theDevice<T>();
    public abstract Object parent { get; set; } // the DBus object
}

public abstract class FsoGps.AbstractReceiver : FsoGps.Receiver, FsoFramework.AbstractObject
{
    protected string receiver_type;
    protected string receiver_transport;
    protected string receiver_port;
    protected int receiver_speed;

    protected Receiver.Status receiver_status;
    protected Receiver.Data receiver_data;
    public Object parent { get; set; } // the DBus object

    protected HashMap<string,FsoGps.Channel> channels;

    construct
    {
        // only one receiver allowed per process
        assert( FsoGps.theReceiver == null );
        FsoGps.theReceiver = this;

        receiver_transport = config.stringValue( "fsogps", "receiver_transport", "serial" );
        receiver_port = config.stringValue( "fsogps", "receiver_port", "/dev/null" );
        receiver_speed = config.intValue( "fsogps", "receiver_speed", 115200 );

        channels = new HashMap<string,FsoGps.Channel>();
        createChannels();

        logger.debug( "FsoGps.AbstractReceiver created: %s:%s@%d".printf( receiver_transport, receiver_port, receiver_speed ) );
    }

    ~AbstractReceiver()
    {
        logger.debug( "FsoGps.AbstractReceiver destroyed: %s:%s@%d".printf( receiver_transport, receiver_port, receiver_speed ) );
    }

    public void registerChannel( string name, FsoGps.Channel channel )
    {
        // not possible to register a channel twice
        assert( ! ( name in channels ) );
        channels[name] = channel;
    }

    private void initData()
    {
        advanceStatus( receiver_status, Status.CLOSED );
        receiver_data = new FsoGps.Receiver.Data();

        configureData();
    }

    public void ensureStatus( int current )
    {
        assert( receiver_status == current );
    }

    /**
     * The only reason for this to be public is that the only authorized source to call this
     * is the command queues / channels and there are no friend classes in Vala. However,
     * it should _never_ be called by any other classes.
     **/
    public void advanceStatus( int current, int next )
    {
        assert( receiver_status == current );
        receiver_status = (Receiver.Status)next;
        signalStatusChanged( next );
    }

    /**
     * Override this to create your channels and assorted transports.
     **/
    protected virtual void createChannels()
    {
    }

    /**
     * Override this to configure the data instance for your modem.
     **/
    protected virtual void configureData()
    {
    }

    /**
     * Override this for modem-specific power handling
     **/
    protected virtual void setPower( bool on )
    {
    }

    //
    // public API
    //

    public virtual bool open()
    {
       // power on
        setPower( true );
        initData();
        ensureStatus( Status.CLOSED );

        var channels = this.channels.values;
        logger.info( "will open %u channel(s)...".printf( channels.size ) );
        foreach( var channel in channels )
        {
            if (!channel.open())
                return false;
        }

        advanceStatus( Status.CLOSED, Status.INITIALIZING );
        return true;
    }

    public virtual void close()
    {
        // close all channels
        var channels = this.channels.values;
        foreach( var channel in channels )
        {
            channel.close();
        }
        // power off
        setPower( false );
    }

    public T theDevice<T>()
    {
        assert( parent != null );
        return (T) parent;
    }

    public int /* FsoGps.Receiver.Status */ status()
    {
        return receiver_status;
    }

    public FsoGps.Receiver.Data data()
    {
        return receiver_data;
    }
}

