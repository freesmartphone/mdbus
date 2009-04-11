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
public delegate string FsoGsm.RequestHandler( FsoGsm.AtCommand command );

const int COMMAND_QUEUE_BUFFER_SIZE = 4096;
const string COMMAND_QUEUE_COMMAND_PREFIX = "AT";
const string COMMAND_QUEUE_COMMAND_POSTFIX = "\r\n";

[Compact]
public class FsoGsm.CommandBundle
{
    public FsoGsm.AtCommand command;
    public string request;
    public RequestHandler getRequest;
    public ResponseHandler handler;
}

public abstract interface FsoGsm.CommandQueue : Object
{
    public abstract void enqueue( AtCommand command, string request, ResponseHandler? handler );
    public abstract void deferred( AtCommand command, RequestHandler getRequest, ResponseHandler? handler );
    public abstract void freeze( bool drain = false );
    public abstract void thaw();
}

public class FsoGsm.AtCommandQueue : FsoGsm.CommandQueue, Object
{
    protected Queue<CommandBundle> q;
    protected FsoFramework.Transport transport;
    protected char* buffer;

    protected void writeNextCommand()
    {
        debug( "writing next command" );
        unowned CommandBundle command = q.peek_tail();
        if ( !transport.isOpen() )
        {
            var ok = transport.open();
            if ( !ok )
                error( "can't open transport" );
        }
        assert( transport.isOpen() );
        writeRequestToTransport( command.request );
    }

    protected void writeRequestToTransport( string request )
    {
        transport.write( COMMAND_QUEUE_COMMAND_PREFIX, 2 );
        transport.write( request, (int)request.size() );
        transport.write( COMMAND_QUEUE_COMMAND_POSTFIX, 2 );
    }

    protected void onResponseFromTransport( string response )
    {
        debug( "response = %s", response.escape( "" ) );
    }

    protected void onHupFromTransport()
    {
        debug( "hup from transport. closing." );
        transport.close();
    }

    protected void _onReadFromTransport( FsoFramework.Transport t )
    {
        debug( "this = %p", this );
        debug( "this.transport = %p", this.transport );
        var bytesread = transport.read( buffer, COMMAND_QUEUE_BUFFER_SIZE );
        buffer[bytesread] = 0;
        onResponseFromTransport( (string)buffer );
    }

    protected void _onHupFromTransport( FsoFramework.Transport t )
    {
        debug( "this = %p", this );
        debug( "this.transport = %p", this.transport );
        onHupFromTransport();
    }

    //=====================================================================//
    // PUBLIC API
    //=====================================================================//

    public AtCommandQueue( FsoFramework.Transport transport )
    {
        debug( "at command queue: %p", this );
        q = new Queue<CommandBundle>();
        this.transport = transport;
        debug( "this.transport = %p", this.transport );
        assert( this.transport != null );
        transport.setDelegates( _onReadFromTransport, _onHupFromTransport );

        buffer = malloc( COMMAND_QUEUE_BUFFER_SIZE );
    }

    ~AtCommandQueue()
    {
        free( buffer );
    }

    public void enqueue( AtCommand command, string request, ResponseHandler? handler )
    {
        debug( "enqueuing %s", request );
        var retriggerWriting = ( q.length == 0 );
        q.push_head( new CommandBundle() { command=command, request=request, getRequest=null, handler=handler } );
        if ( retriggerWriting )
            writeNextCommand();
    }

    public void deferred( AtCommand command, RequestHandler getRequest, ResponseHandler? handler )
    {
        debug( "enqueuing deferred request %s", getRequest( command ) );
        var retriggerWriting = ( q.length == 0 );
        q.push_head( new CommandBundle() { command=command, request=null, getRequest=getRequest, handler=handler } );
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

    /*
    public virtual void onReadFromTransport( void* data, int len )
    {
        message( "READ from transport" );
    }

    public virtual void onHupFromTransport()
    {
        message( "HUP from transport" );
    }
    */

}

}

