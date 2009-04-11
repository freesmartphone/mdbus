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

namespace FsoGsm { public FsoGsm.Modem theModem; }

public abstract interface FsoGsm.Modem : GLib.Object
{
    public enum Status
    {
        /** Initial state, Transport is closed **/
        CLOSED,
        /** Transport has been successfully opened **/
        OPENED,
        /** Initialization commands are being sent **/
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
        RESUMING
    }

    public abstract bool open();
    public abstract bool close();
    //FIXME: Should be Status with Vala >= 0.7
    public abstract int status();

    public abstract FsoGsm.AtCommand atCommandFactory( string command );
}

public abstract class FsoGsm.AbstractModem : FsoGsm.Modem, FsoFramework.AbstractObject
{
    protected string modem_type;
    protected string modem_transport;
    protected string modem_port;
    protected int modem_speed;

    protected FsoGsm.Modem.Status modem_status;

    protected GLib.HashTable<string, FsoGsm.Channel> channels;
    protected GLib.HashTable<string, FsoGsm.AtCommand> commands;

    construct
    {
        // only one modem allowed per process
        assert( FsoGsm.theModem == null );
        FsoGsm.theModem = this;

        modem_transport = config.stringValue( "fsogsm", "modem_transport", "serial" );
        modem_port = config.stringValue( "fsogsm", "modem_port", "file:/dev/null" );
        modem_speed = config.intValue( "fsogsm", "modem_speed", 115200 );

        channels = new HashTable<string, FsoGsm.Channel>( GLib.str_hash, GLib.str_equal );

        registerAtCommands();
        createChannels();
        logger.debug( "FsoGsm.AbstractModem created: %s:%s@%d".printf( modem_transport, modem_port, modem_speed ) );
    }

    private void registerAtCommands()
    {
        commands = new HashTable<string, FsoGsm.AtCommand>( GLib.str_hash, GLib.str_equal );
        registerGenericAtCommands( commands );
        registerCustomAtCommands( commands );
    }

    /**
     * Override this to register additional AT commands specific to your modem or
     * override generic AT commands with modem-specific versions.
     **/
    protected virtual void registerCustomAtCommands( HashTable<string, FsoGsm.AtCommand> commands )
    {
    }

    /**
     * Override this to create your channels and transports. @return true, if successful. False, otherwise.
     **/
    protected virtual bool createChannels()
    {
        return false;
    }

    //=====================================================================//
    // PUBLIC API
    //=====================================================================//

    public virtual bool open()
    {
        return false;
    }

    public virtual bool close()
    {
        return false;
    }

    public int /* FsoGsm.Modem.Status */ status()
    {
        return modem_status;
    }

    public AtCommand atCommandFactory( string command )
    {
        var cmd = commands.lookup( command );
        assert( cmd != null );
        return cmd;
    }

    /**
     * The only reason for this to be public is that the only authorized source to call this
     * is the command queues / channels and there are no friend classes in Vala. However,
     * it should _never_ be called by any other classes.
     **/
    public void advanceStatus( int current, int next )
    {
        assert( modem_status == current );

        switch ( next )
        {
            case FsoGsm.Modem.Status.OPENED:
                break;
            default:
                assert_not_reached();
        }
    }
}

public abstract class FsoGsm.AbstractGsmModem : FsoGsm.AbstractModem
{
}

public abstract class FsoGsm.AbstractCdmaModem : FsoGsm.AbstractModem
{
}
