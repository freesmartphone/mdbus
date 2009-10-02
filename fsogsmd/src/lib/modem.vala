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

namespace FsoGsm { public FsoGsm.Modem theModem; }

public class FsoGsm.ModemData : GLib.Object
{
    public int speakerVolumeMinimum;
    public int speakerVolumeMaximum;

    public bool simBuffersSms;

    public AtNewMessageIndication cnmiSmsBufferedCb;
    public AtNewMessageIndication cnmiSmsBufferedNoCb;
    public AtNewMessageIndication cnmiSmsDirectCb;
    public AtNewMessageIndication cnmiSmsDirectNoCb;
}

public abstract interface FsoGsm.Modem : FsoFramework.AbstractObject
{
    public const uint DEFAULT_RETRY = 3;

    public enum Status
    {
        /** Initial state, Transport is closed **/
        CLOSED,
        /** Transport open, initialization commands are being sent **/
        INITIALIZING,
        /** Initialized, SIM status unknown **/
        ALIVE,
        /** Initialized, SIM is not inserted **/
        ALIVE_NO_SIM,
        /** Initialized, SIM is locked **/
        ALIVE_SIM_LOCKED,
        /** Initialized, SIM is unlocked **/
        ALIVE_SIM_UNLOCKED,
        /** Initialized, SIM is ready for access **/
        ALIVE_SIM_READY,
        /** Initialized, SIM is booked into the network and reachable **/
        ALIVE_REGISTERED,
        /** Suspend commands are being sent **/
        SUSPENDING,
        /** Suspended **/
        SUSPENDED,
        /** Resume commands are being sent **/
        RESUMING,
        /* ALIVE */
    }

    public abstract bool open();
    public abstract void close();
    //FIXME: Should be FsoGsm.Modem.Status with Vala >= 0.7
    public abstract int status();

    public abstract void registerChannel( string name, FsoGsm.Channel channel );
    //FIXME: What was this for?
    public abstract string[] commandSequence( string purpose );

    public abstract T createMediator<T>() throws FreeSmartphone.Error;
    public abstract T createAtCommand<T>( string command ) throws FreeSmartphone.Error;

    // All commands go through this function, so that the modem can
    // easily decide which channel a certain command goes to at a
    // given time
    public abstract async string[] processCommandAsync( AtCommand command, string request, uint retry = DEFAULT_RETRY );

    //FIXME: Might also create a channel that implements round-robin transparently?!
    public abstract FsoGsm.Channel channel( string category );

    public signal void signalStatusChanged( /* FsoGsm.Modem.Status */ int status );

    public abstract FsoGsm.ModemData data();
}

public abstract class FsoGsm.AbstractModem : FsoGsm.Modem, FsoFramework.AbstractObject
{
    protected string modem_type;
    protected string modem_transport;
    protected string modem_port;
    protected int modem_speed;

    protected string[] modem_init;

    protected FsoGsm.Modem.Status modem_status;
    protected FsoGsm.ModemData modem_data;

    protected HashMap<string,FsoGsm.Channel> channels;
    protected HashMap<string,FsoGsm.AtCommand> commands;
    protected HashMap<Type,Type> mediators;

    construct
    {
        // only one modem allowed per process
        assert( FsoGsm.theModem == null );
        FsoGsm.theModem = this;

        modem_transport = config.stringValue( "fsogsm", "modem_transport", "serial" );
        modem_port = config.stringValue( "fsogsm", "modem_port", "/dev/null" );
        modem_speed = config.intValue( "fsogsm", "modem_speed", 115200 );
        modem_init = config.stringListValue( "fsogsm", "modem_init", { "E0Q0V1" } );

        channels = new HashMap<string,FsoGsm.Channel>();

        initData();
        registerMediators();
        registerAtCommands();
        createChannels();

        logger.debug( "FsoGsm.AbstractModem created: %s:%s@%d".printf( modem_transport, modem_port, modem_speed ) );
    }

    private void initData()
    {
        modem_status = Status.CLOSED;
        modem_data = new FsoGsm.ModemData();

        modem_data.cnmiSmsBufferedCb    = AtNewMessageIndication() { mode=2, mt=1, bm=2, ds=1, bfr=1 };
        modem_data.cnmiSmsBufferedNoCb  = AtNewMessageIndication() { mode=2, mt=1, bm=0, ds=0, bfr=0 };
        modem_data.cnmiSmsDirectCb      = AtNewMessageIndication() { mode=2, mt=2, bm=2, ds=1, bfr=1 };
        modem_data.cnmiSmsDirectNoCb    = AtNewMessageIndication() { mode=2, mt=2, bm=0, ds=0, bfr=0 };

        configureData();
    }

    private void registerMediators()
    {
        mediators = new HashMap<Type,Type>();
        registerGenericAtMediators( mediators );
        registerCustomMediators( mediators );
    }

    private void registerAtCommands()
    {
        commands = new HashMap<string,FsoGsm.AtCommand>();
        registerGenericAtCommands( commands );
        registerCustomAtCommands( commands );
    }

    /**
     * Override this to register additional mediators specific to your modem or
     * override generic mediators with modem-specific versions.
     **/
    protected virtual void registerCustomMediators( HashMap<Type,Type> mediators )
    {
    }

    /**
     * Override this to register additional AT commands specific to your modem or
     * override generic AT commands with modem-specific versions.
     **/
    protected virtual void registerCustomAtCommands( HashMap<string,FsoGsm.AtCommand> commands )
    {
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
     * Implement this to create the command/channel-assignment function.
     **/
    protected abstract FsoGsm.Channel channelForCommand( FsoGsm.AtCommand command, string request );

    //=====================================================================//
    // PUBLIC API
    //=====================================================================//

    public virtual bool open()
    {
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
        var channels = this.channels.values;
        foreach( var channel in channels )
            channel.close();
    }

    public int /* FsoGsm.Modem.Status */ status()
    {
        return modem_status;
    }

    public FsoGsm.ModemData data()
    {
        return modem_data;
    }

    public virtual FsoGsm.Channel channel( string category )
    {
        return channels[category];
    }

    public T createMediator<T>() throws FreeSmartphone.Error
    {
        Type typ = mediators[typeof(T)];
        assert( typ != typeof(T) ); // we do NOT want the interface, else things will go havoc
        if ( typ == Type.INVALID )
        {
            throw new FreeSmartphone.Error.INTERNAL_ERROR( "Requested mediator '%s' unknown".printf( typeof(T).name() ) );
        }
        T obj = Object.new( typ );
        assert( obj != null );
        return obj;
    }

    public T createAtCommand<T>( string command ) throws FreeSmartphone.Error
    {
        AtCommand? cmd = commands[command];
        if (cmd == null )
        {
            throw new FreeSmartphone.Error.INTERNAL_ERROR( "Requested AT command '%s' unknown".printf( command ) );
        }
        return (T) cmd;
    }

    public async string[] processCommandAsync( AtCommand command, string request, uint retry = DEFAULT_RETRY )
    {
        var channel = channelForCommand( command, request );
        var response = yield channel.enqueueAsyncYielding( command, request, retry );
        return response;
    }

    public Type mediatorFactory( Type mediator ) throws FreeSmartphone.Error
    {
        Type typ = mediators[mediator];
        if ( typ == Type.INVALID )
        {
            throw new FreeSmartphone.Error.INTERNAL_ERROR( "Requested mediator '%s' unknown".printf( mediator.name() ) );
        }
        return typ;
    }

    public AtCommand atCommandFactory( string command ) throws FreeSmartphone.Error
    {
        AtCommand? cmd = commands[command];
        if (cmd == null )
        {
            throw new FreeSmartphone.Error.INTERNAL_ERROR( "Requested AT command '%s' unknown".printf( command ) );
        }
        return cmd;
    }

    public void registerChannel( string name, FsoGsm.Channel channel )
    {
        assert( channels != null );
        assert( channels[name] == null );
        channels[name] = channel;
    }

    public void ensureStatus( int current )
    {
        assert( modem_status == current );
    }

    /**
     * The only reason for this to be public is that the only authorized source to call this
     * is the command queues / channels and there are no friend classes in Vala. However,
     * it should _never_ be called by any other classes.
     **/
    public void advanceStatus( int current, int next )
    {
        assert( modem_status == current );
        modem_status = (Modem.Status)next;
        signalStatusChanged( next );
    }

    public string[] commandSequence( string purpose )
    {
        if ( purpose == "init" )
        {
            return modem_init;
        }
        else
        {
            return { "" };
        }
    }
}

public abstract class FsoGsm.AbstractGsmModem : FsoGsm.AbstractModem
{
}

public abstract class FsoGsm.AbstractCdmaModem : FsoGsm.AbstractModem
{
}
