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

public abstract interface FsoGsm.Modem : GLib.Object
{
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
    //FIXME: Should be Status with Vala >= 0.7
    public abstract int status();

    public abstract void registerChannel( string name, FsoGsm.Channel channel );
    public abstract string[] commandSequence( string purpose );

    public abstract T createMediator<T>() throws FreeSmartphone.Error;
    public abstract Type mediatorFactory( Type mediator ) throws FreeSmartphone.Error;
    public abstract FsoGsm.AtCommand atCommandFactory( string command ) throws FreeSmartphone.Error;

    public abstract FsoGsm.Channel channel( string category );

    public signal void signalStatusChanged( /* FsoGsm.Modem.Status */ int status );
}

public abstract class FsoGsm.AbstractModem : FsoGsm.Modem, FsoFramework.AbstractObject
{
    protected string modem_type;
    protected string modem_transport;
    protected string modem_port;
    protected int modem_speed;

    protected string[] modem_init;

    protected FsoGsm.Modem.Status modem_status;

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
        modem_init = config.stringListValue( "fsogsm", "modem_init", { "ZE0Q0V1" } );

        channels = new HashMap<string,FsoGsm.Channel>();

        registerMediators();
        registerAtCommands();
        createChannels();

        modem_status = Status.CLOSED;

        logger.debug( "FsoGsm.AbstractModem created: %s:%s@%d".printf( modem_transport, modem_port, modem_speed ) );
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
    protected abstract void createChannels();

    //=====================================================================//
    // PUBLIC API
    //=====================================================================//

    public virtual bool open()
    {
        ensureStatus( Status.CLOSED );

        var channels = this.channels.get_values();
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
        var channels = this.channels.get_values();
        foreach( var channel in channels )
            channel.close();
    }

    public int /* FsoGsm.Modem.Status */ status()
    {
        return modem_status;
    }

    public virtual FsoGsm.Channel channel( string category )
    {
        return channels[category];
    }

    public T createMediator<T>() throws FreeSmartphone.Error
    {
        Type typ = mediators[typeof(T)];
        assert( typ != typeof(T) ); // we do NOT want the interface
        if ( typ == Type.INVALID )
        {
            throw new FreeSmartphone.Error.INTERNAL_ERROR( "Requested mediator '%s' unknown".printf( typeof(T).name() ) );
        }
        return (T) ( new Object( typ ) );
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
            throw new FreeSmartphone.Error.INTERNAL_ERROR( "Requested at command '%s' unknown".printf( command ) );
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
