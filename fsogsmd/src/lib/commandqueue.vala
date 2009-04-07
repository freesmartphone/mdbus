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

public delegate void FsoGsm.ResponseHandler( FsoGsm.AtCommand command, string response );

public struct FsoGsm.Command
{
    public string command;
    public ResponseHandler handler;
}

public abstract interface FsoGsm.CommandQueue : Object
{
    public abstract void enqueue( Command command );
    public abstract void freeze( bool drain = false );
    public abstract void thaw();
}

public class FsoGsm.BaseCommandQueue : FsoGsm.CommandQueue, Object
{
    protected Queue<Command?> q;
    protected FsoFramework.Transport transport;

    protected void writeNextCommand()
    {
        debug( "writing next command" );
        var command = q.peek_tail();
        if ( !transport.isOpen() )
        {
            var ok = transport.open();
            if ( !ok )
                error( "can't open transport" );
        }
        assert( transport.isOpen() );
        transport.write( command.command, (int)command.command.size() );
    }

    protected void onReadFromTransport( FsoFramework.Transport transport )
    {
        debug( "read from transport" );
        //TODO: read from transport, feed to parser, then back
    }

    protected void onHupFromTransport( FsoFramework.Transport transport )
    {
        debug( "HUP from transport" );
    }

    //=====================================================================//
    // PUBLIC API
    //=====================================================================//

    public BaseCommandQueue( FsoFramework.Transport transport )
    {
        q = new Queue<Command?>();
        this.transport = transport;
        transport.setDelegates( onReadFromTransport, onHupFromTransport );
    }

    public void enqueue( Command command )
    {
        debug( "enqueuing %s", command.command );
        var retriggerWriting = ( q.length == 0 );
        q.push_head( command );
        if ( retriggerWriting )
            writeNextCommand();
    }

    public void freeze( bool drain = false )
    {
        assert_not_reached();
    }

    public void thaw()
    {
        assert_not_reached();
    }

}
