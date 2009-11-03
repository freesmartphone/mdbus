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

public class PhonebookParams
{
    public int min;
    public int max;

    public PhonebookParams( int min, int max )
    {
        this.min = min;
        this.max = max;
    }
}

public abstract interface FsoGsm.Modem : FsoFramework.AbstractObject
{
    public class Data : GLib.Object
    {
        public int alarmCleared;

        public AtNewMessageIndication cnmiSmsBufferedCb;
        public AtNewMessageIndication cnmiSmsBufferedNoCb;
        public AtNewMessageIndication cnmiSmsDirectCb;
        public AtNewMessageIndication cnmiSmsDirectNoCb;

        public bool simHasReadySignal;

        public int speakerVolumeMinimum;
        public int speakerVolumeMaximum;

        public FreeSmartphone.GSM.SIMAuthStatus simAuthStatus;

        public bool simBuffersSms;

        public HashMap<string,PhonebookParams> simPhonebooks;

        public string charset;

        public bool simInserted;
        public bool simUnlocked;
        public bool simReady;
        public bool simRegistered;
    }

    public const uint DEFAULT_RETRY = 3;

    //TODO: Think about exposing a global modem state through DBus -- possibly
    //      reusing this as internal status as well -- rather than double bookkeeping
    public enum Status
    {
        /** Initial state, Transport is closed **/
        CLOSED,
        /** Transport open, initialization commands are being sent **/
        INITIALIZING,
        /** Initialized, SIM status unknown **/
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

    // DBus Service API
    public abstract bool open();
    public abstract void close();
    public abstract void injectResponse( string command, string channel ); // DEBUG ONLY

    // Channel API
    public abstract void registerChannel( string name, FsoGsm.Channel channel );
    public abstract void advanceToState( Modem.Status status );
    public abstract string[] commandSequence( string purpose );
    public signal void signalStatusChanged( Modem.Status status );

    // Mediator API
    public abstract T createMediator<T>() throws FreeSmartphone.Error;
    public abstract T createAtCommand<T>( string command ) throws FreeSmartphone.Error;
    public abstract T theDevice<T>();
    public abstract Object parent { get; set; } // the DBus object
    public abstract CallHandler callhandler { get; set; } // the Call handler
    public abstract SmsHandler smshandler { get; set; } // the Sms handler

    // Command Queue API
    public abstract async string[] processCommandAsync( AtCommand command, string request, uint retry = DEFAULT_RETRY );
    public abstract async string[] processPduCommandAsync( AtCommand command, string request, uint retry = DEFAULT_RETRY );
    public abstract FsoGsm.Channel channel( string category );

    // Misc. Accessors
    public abstract Modem.Status status();
    public abstract FsoGsm.Modem.Data data();
}

/**
 * @class FsoGsm.AbstractModem
 **/
public abstract class FsoGsm.AbstractModem : FsoGsm.Modem, FsoFramework.AbstractObject
{
    protected string modem_type;
    protected string modem_transport;
    protected string modem_port;
    protected int modem_speed;

    protected string[] modem_init;

    protected FsoGsm.Modem.Status modem_status;
    protected FsoGsm.Modem.Data modem_data;

    protected HashMap<string,FsoGsm.Channel> channels;
    protected HashMap<string,FsoGsm.AtCommand> commands;
    protected HashMap<Type,Type> mediators;

    protected UnsolicitedResponseHandler urc;

    protected Object parent { get; set; } // the DBus object
    protected CallHandler callhandler { get; set; } // the Call handler
    protected SmsHandler smshandler { get; set; } // the SMS handler

    construct
    {
        // only one modem allowed per process
        assert( FsoGsm.theModem == null );
        FsoGsm.theModem = this;

        modem_transport = config.stringValue( "fsogsm", "modem_transport", "serial" );
        modem_port = config.stringValue( "fsogsm", "modem_port", "/dev/null" );
        modem_speed = config.intValue( "fsogsm", "modem_speed", 115200 );
        modem_init = config.stringListValue( "fsogsm", "modem_init", { "E0Q0V1", "+CMEE=1", "+CRC=1" } );

        registerHandlers();
        registerMediators();
        registerAtCommands();
        channels = new HashMap<string,FsoGsm.Channel>();
        createChannels();

        logger.debug( "FsoGsm.AbstractModem created: %s:%s@%d".printf( modem_transport, modem_port, modem_speed ) );
    }

    ~AbstractModem()
    {
        logger.debug( "FsoGsm.AbstractModem destroyed: %s:%s@%d".printf( modem_transport, modem_port, modem_speed ) );
    }

    private void initData()
    {
        advanceToState( Modem.Status.CLOSED );

        modem_data = new FsoGsm.Modem.Data();

        //modem_data.simidentification = "unknown";

        modem_data.charset = "unknown";
        modem_data.simHasReadySignal = false;

        modem_data.speakerVolumeMinimum = -1;
        modem_data.speakerVolumeMaximum = -1;

        modem_data.alarmCleared = 946684800; // 00/01/01,00:00:00 (default for SIEMENS mc75i)
        modem_data.simAuthStatus = FreeSmartphone.GSM.SIMAuthStatus.UNKNOWN;
        modem_data.simBuffersSms = true;

        modem_data.cnmiSmsBufferedCb    = AtNewMessageIndication() { mode=2, mt=1, bm=2, ds=1, bfr=1 };
        modem_data.cnmiSmsBufferedNoCb  = AtNewMessageIndication() { mode=2, mt=1, bm=0, ds=0, bfr=0 };
        modem_data.cnmiSmsDirectCb      = AtNewMessageIndication() { mode=2, mt=2, bm=2, ds=1, bfr=1 };
        modem_data.cnmiSmsDirectNoCb    = AtNewMessageIndication() { mode=2, mt=2, bm=0, ds=0, bfr=0 };

        modem_data.simPhonebooks = new HashMap<string,PhonebookParams>();

        configureData();
    }

    private void registerHandlers()
    {
        urc = createUnsolicitedHandler();
        callhandler = createCallHandler();
        smshandler = createSmsHandler();
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
     * Override this to return a custom type of urc handler to be used for this modem.
     **/
    protected virtual UnsolicitedResponseHandler createUnsolicitedHandler()
    {
        return new AtUnsolicitedResponseHandler();
    }

    /**
     * Override this to return a custom type of call handler to be used for this modem.
     **/
    protected virtual CallHandler createCallHandler()
    {
        return new GenericAtCallHandler();
    }

    /**
     * Override this to return a custom type of SMS handler to be used for this modem.
     **/
    protected virtual SmsHandler createSmsHandler()
    {
        return new AtSmsHandler();
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

    /**
     * Implement this to create the command/channel-assignment function.
     **/
    protected abstract FsoGsm.Channel channelForCommand( FsoGsm.AtCommand command, string request );

    //=====================================================================//
    // PUBLIC API
    //=====================================================================//

    public virtual bool open()
    {
        // power on
        setPower( true );
        initData();

        var channels = this.channels.values;
        //FIXME: If we can't open all channels, we should close all others
        logger.info( "will open %u channel(s)...".printf( channels.size ) );
        foreach( var channel in channels )
        {
            if (!channel.open())
                return false;
        }

        advanceToState( Modem.Status.INITIALIZING );

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

    public virtual void injectResponse( string command, string channel )
    {
        var chan = this.channels[channel];
        if ( chan == null )
        {
            //FIXME: dbus error?
            warning( @"No channel $channel" );
            return;
        }
        chan.injectResponse( command );
    }

    public T theDevice<T>()
    {
        assert( parent != null );
        return (T) parent;
    }

    public Modem.Status status()
    {
        return modem_status;
    }

    public FsoGsm.Modem.Data data()
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

    public async string[] processPduCommandAsync( AtCommand command, string request, uint retry = DEFAULT_RETRY )
    {
        var channel = channelForCommand( command, request );
        var pdurequest = request.split( "\n" );
        assert( pdurequest.length == 2 );
        var continuation = yield channel.enqueueAsyncYielding( command, pdurequest[0], retry );
        assert( continuation.length == 1 && continuation[0] == "> " );
        var response = yield channel.enqueueAsyncYielding( command, pdurequest[1], retry );
        return response;
    }

    public void processUnsolicitedResponse( string prefix, string righthandside, string? pdu = null )
    {
        // lookup and forward to unsolicited object, if not found, handle on your own?
        assert( urc != null );
        if ( !urc.dispatch( prefix, righthandside, pdu ) )
        {
            logger.warning( "No handler for URC '%s', please report to smartphones-userland@linuxtogo.org".printf( prefix ) );
        }
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
        channel.registerUnsolicitedHandler( this.processUnsolicitedResponse );
    }

    /**
     * The only reason for this to be public is that the only authorized source to call this
     * is the command queues / channels and there are no friend classes in Vala. However,
     * it should _never_ be called by any other classes.
     **/
    public void advanceToState( Modem.Status next )
    {
        // if there is no SIM readyness signal, assume it's ready NOW
        if ( ( next == Modem.Status.ALIVE_SIM_UNLOCKED ) && ( !modem_data.simHasReadySignal ) )
        {
            modem_status = Modem.Status.ALIVE_SIM_READY;
        }
        else
        {
            modem_status = next;
        }
        signalStatusChanged( modem_status );
        logger.info( "Modem Status changed to %s".printf( FsoFramework.StringHandling.enumToString( typeof(Modem.Status), modem_status ) ) );
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
