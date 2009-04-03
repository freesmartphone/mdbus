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

public delegate void FsoGsm.ResponseHandler( string response );

public struct FsoGsm.Command
{
    public string command;
    public ResponseHandler handler;
}

public abstract interface FsoGsm.CommandQueue : Object
{
}

public class FsoGsm.BaseCommandQueue : FsoGsm.CommandQueue, Object
{
    protected Queue<Command?> q;
    protected FsoFramework.Transport transport;

    /**
     * create new command queue using @a transport.
     **/
    public BaseCommandQueue( FsoFramework.Transport transport )
    {
        q = new Queue<Command?>();
        this.transport = transport;
    }

    public void enqueue( Command command )
    {
        var retriggerWriting = ( q.length == 0 );
        q.push_head( command );
        if ( retriggerWriting )
            writeNextCommand();
    }

    public void writeNextCommand()
    {
        var command = q.peek_tail();
        transport.write( command.command, (int)command.command.size() );
    }

}
