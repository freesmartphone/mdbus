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
    public abstract bool open();
    public abstract bool close();

    public abstract FsoGsm.AtCommand atCommandFactory( string command );
}

[Compact]
public class FsoGsm.Channel
{
    public FsoFramework.Transport transport;
    public FsoGsm.Parser parser;
    public FsoGsm.CommandQueue queue;
}

public abstract class FsoGsm.AbstractModem : FsoGsm.Modem, FsoFramework.AbstractObject
{
    protected string modem_type;
    protected string modem_transport;
    protected string modem_port;
    protected int modem_speed;

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

        logger.debug( "FsoGsm.AbstractModem created: %s:%s@%d".printf( modem_transport, modem_port, modem_speed ) );
    }

    // TODO: create necessary amount of transports
    // TODO: create necessary amount of at command queues

    // TODO: init status signals


    public AtCommand atCommandFactory( string command )
    {
        var cmd = commands.lookup( command );
        assert( cmd != null );
        return cmd;
    }

    protected void registerAtCommands()
    {
        commands = new HashTable<string, FsoGsm.AtCommand>( GLib.str_hash, GLib.str_equal );
        registerGenericAtCommands( commands );
        registerCustomAtCommands( commands );
    }

    /**
     * Override this to register additional AT commands specific to your modem or
     * override generic AT commands with modme-specific versions.
     **/
    protected virtual void registerCustomAtCommands( HashTable<string, FsoGsm.AtCommand> commands )
    {
    }

    /**
     * Override this to populate modem setup sequences specific to your modem.
     **/
    protected virtual void populateModemSetupCommands( HashTable<string, FsoGsm.AtCommand> commands )
    {
    }

    public virtual bool open()
    {
        return false;
    }

    public virtual bool close()
    {
        return false;
    }
}

public abstract class FsoGsm.AbstractGsmModem : FsoGsm.AbstractModem
{
    protected override void populateModemSetupCommands( HashTable<string, FsoGsm.AtCommand> commands )
    {
    }
}

public abstract class FsoGsm.AbstractCdmaModem : FsoGsm.AbstractModem
{
}
