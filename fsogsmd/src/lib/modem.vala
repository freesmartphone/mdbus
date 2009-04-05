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

public abstract interface FsoGsm.Modem : GLib.Object
{
    public abstract bool open();
    public abstract bool close();
}

public struct FsoGsm.Channel
{
    public FsoFramework.Transport transport;
    public FsoGsm.CommandQueue queue;
}

public abstract class FsoGsm.AbstractModem : FsoGsm.Modem, FsoFramework.AbstractObject
{
    protected string modem_type;
    protected string modem_transport;
    protected string modem_port;
    protected int modem_speed;

    HashTable<string, FsoGsm.Channel?> channels;

    construct
    {
        modem_transport = config.stringValue( "fsogsm", "modem_transport", "serial" );
        modem_port = config.stringValue( "fsogsm", "modem_port", "file:/dev/null" );
        modem_speed = config.intValue( "fsogsm", "modem_speed", 115200 );

        channels = new HashTable<string, FsoGsm.Channel?>( GLib.str_hash, GLib.str_equal );

        logger.debug( "FsoGsm.AbstractModem created: %s:%s@%d".printf( modem_transport, modem_port, modem_speed ) );
    }

    // TODO: create necessary amount of transports
    // TODO: create necessary amount of at command queues

    // TODO: init status signals

    public virtual bool open()
    {
        return false;
    }

    public virtual bool close()
    {
        return false;
    }
}
