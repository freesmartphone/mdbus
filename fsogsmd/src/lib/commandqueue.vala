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

public delegate void FsoGsm.ResponseHandler( FsoGsm.AtCommand command, string[] response );
public delegate string FsoGsm.RequestHandler( FsoGsm.AtCommand command );
public delegate void FsoGsm.UnsolicitedHandler( string prefix, string response, string? pdu = null );

const uint COMMAND_QUEUE_CHANNEL_TIMEOUT = 10;
const int  COMMAND_QUEUE_BUFFER_SIZE = 4096;
const string COMMAND_QUEUE_COMMAND_PREFIX = "AT";
const string COMMAND_QUEUE_COMMAND_POSTFIX = "\r\n";

public class FsoGsm.CommandBundle
{
    public FsoGsm.AtCommand command;
    public string request;
    public uint retry;
    public RequestHandler getRequest;
    public ResponseHandler handler;
    public string[] response;
    public SourceFunc callback;
}

public abstract interface FsoGsm.CommandQueue : Object
{
    public const uint DEFAULT_RETRY = 3;
    /**
     * Register @a UnsolicitedHandler delegate that will be called for incoming URCs
     **/
    public abstract void registerUnsolicitedHandler( UnsolicitedHandler urchandler );
    /**
     * Enqueue new @a AtCommand command, sending the request as @a string request.
     * Coroutine will yield the response.
     **/
    public abstract async string[] enqueueAsyncYielding( AtCommand command, string request, uint retry = DEFAULT_RETRY );
    /**
     * Enqueue new @a AtCommand command, sending the request as @a string request.
     * The @a SourceFunc callback will be called. The response from the peer is set in the command bundle.
     **/
    public abstract void enqueueAsync( AtCommand command, string request, SourceFunc? callback = null, string[]? response = null, uint retry = DEFAULT_RETRY );
    /**
     * Enqueue new @a AtCommand command, sending the request as @a string request.
     * The @a ResponseHandler handler will be called with the response from the peer.
     **/
    public abstract void enqueue( AtCommand command, string request, ResponseHandler? handler = null, uint retry = DEFAULT_RETRY );
    /**
     * Enqueue new @a AtCommand command. When the command is due for sending, the
     * @a RequestHandler getRequest will be called to gather the request string.
     **/
    public abstract void deferred( AtCommand command, RequestHandler getRequest, ResponseHandler? handler = null, uint retry = DEFAULT_RETRY );
    /**
     * Halt the Queue operation. Stop accepting any more commands. If drain is true, send
     * all commands that are in the Queue at this point.
     **/
    public abstract void freeze( bool drain = false );
    /**
     * Resume the Queue operation.
     **/
    public abstract void thaw();
}

public class FsoGsm.AtCommandQueue : FsoGsm.CommandQueue, FsoFramework.AbstractObject
{
    protected LinkedList<CommandBundle> q;
    protected CommandBundle current;
    protected uint timeout;

    protected FsoFramework.Transport transport;
    protected FsoGsm.Parser parser;
    protected char* buffer;
    protected UnsolicitedHandler urchandler;

    protected void _writeRequestToTransport( string request )
    {
        transport.write( COMMAND_QUEUE_COMMAND_PREFIX, 2 );
        transport.write( request, (int)request.size() );
        transport.write( COMMAND_QUEUE_COMMAND_POSTFIX, 2 );
        timeout = Timeout.add_seconds( COMMAND_QUEUE_CHANNEL_TIMEOUT, _onTimeout );
    }

    protected void _onReadFromTransport( FsoFramework.Transport t )
    {
        if ( timeout > 0 )
        {
            Source.remove( timeout );
        }
        var bytesread = transport.read( buffer, COMMAND_QUEUE_BUFFER_SIZE );
        buffer[bytesread] = 0;
        onReadFromTransport( (string)buffer );
    }

    protected void _onHupFromTransport( FsoFramework.Transport t )
    {
        onHupFromTransport();
    }

    protected bool _onTimeout()
    {
        // FIXME: Might check whether we already have something in the
        // parser buffer (i.e. partial response), since then we need to
        // reset the parser state before continuing
        if ( current.retry-- > 0 )
        {
            logger.warning( "Transport did not reply to command '%s'. Resending...".printf( current.request ) );
            _writeRequestToTransport( current.request );
        }
        else
        {
            logger.error( "Transport did (even after retrying) not reply to command '%s'".printf( current.request ) );

            onResponseTimeout( current );

            current = null;
            Idle.add( checkRestartingQ );
        }
        return false;
    }

    protected bool _haveCommand()
    {
        return ( current != null );
    }

    protected bool _expectedPrefix( string line )
    {
        return true;
    }

    protected void _solicitedCompleted( string[] response )
    {
        assert( current != null );

        onSolicitedResponse( current, response );
        current = null;

        Idle.add( checkRestartingQ );
    }

    protected void _unsolicitedCompleted( string[] response )
    {
        logger.debug( "UNsolicited completed: %s".printf( FsoFramework.StringHandling.stringListToString( response ) ) );

        assert( ":" in response[0] ); // free-form URCs not yet supported

        var strings = response[0].split( ":" );
        assert( strings.length == 2 ); // multiple ':' in URC not yet supported

        if ( response.length == 1 ) // simple URCs
        {
            urchandler( strings[0], strings[1].offset( 1 ) );
        }
        else if ( response.length == 2 ) // PDU URC
        {
            urchandler( strings[0], strings[1].offset( 1 ), response[1] );
        }
        else
        {
            logger.critical( "Can't handle URC w/ more than 2 lines!" );
        }
    }

    //=====================================================================//
    // SUBCLASSING API
    //=====================================================================//

    protected void writeNextCommand()
    {
        logger.debug( "Writing next command" );
        current = q.poll_head();
        _writeRequestToTransport( current.request );
    }

    protected void onReadFromTransport( string response )
    {
        if ( response.length > 0 )
        {
            logger.debug( "Read '%s'".printf( response.escape( "" ) ) );
            parser.feed( response, (int)response.length );
        }
        else
        {
            onHupFromTransport();
        }
    }

    protected void onHupFromTransport()
    {
        logger.debug( "HUP from transport. closing." );
        transport.close();
        //FIXME: Try to open again or leave that to the higher layers?
    }

    protected void onSolicitedResponse( CommandBundle bundle, string[] response )
    {
        logger.debug( "Solicited completed: %s -> %s".printf( bundle.request, FsoFramework.StringHandling.stringListToString( response ) ) );

        /*
        if ( bundle.handler != null )
        bundle.handler( bundle.command, response );
        */

        if ( bundle.callback != null )
        {
            bundle.response = response;
            bundle.callback();
        }
    }

    protected void onResponseTimeout( CommandBundle bundle )
    {
        onSolicitedResponse( bundle, new string[] { "+EXT: ERROR 261271" } );
    }

    //=====================================================================//
    // PUBLIC API
    //=====================================================================//

    public AtCommandQueue( FsoFramework.Transport transport, FsoGsm.Parser parser )
    {
        q = new LinkedList<CommandBundle>();
        this.transport = transport;
        this.parser = parser;
        transport.setDelegates( _onReadFromTransport, _onHupFromTransport );
        parser.setDelegates( _haveCommand, _expectedPrefix, _solicitedCompleted, _unsolicitedCompleted );

        buffer = malloc( COMMAND_QUEUE_BUFFER_SIZE );
    }

    ~AtCommandQueue()
    {
        free( buffer );
    }

    public override string repr()
    {
        return "<Unnamed AtCommandQueue>";
    }

    public void registerUnsolicitedHandler( UnsolicitedHandler urchandler )
    {
        assert( this.urchandler == null );
        this.urchandler = urchandler;
    }

    public void enqueue( AtCommand command, string request, ResponseHandler? handler = null, uint retry = DEFAULT_RETRY )
    {
        logger.debug( "enqueuing %s".printf( request ) );
        var retriggerWriting = ( q.size == 0 );
        q.offer_tail( new CommandBundle() {
            command=command,
            request=request,
            getRequest=null,
            handler=handler,
            retry=retry } );
        Idle.add( checkRestartingQ );
    }

    public void enqueueAsync( AtCommand command, string request, SourceFunc? callback = null, string[]? response = null, uint retry = DEFAULT_RETRY )
    {
        var retriggerWriting = ( q.size == 0 );
        logger.debug( "enqueuing %s [q size = %d], retrigger = %d".printf( request, q.size, (int)retriggerWriting ) );
        q.offer_tail( new CommandBundle() {
            command=command,
            request=request,
            getRequest=null,
            callback=callback,
            response=response,
            retry=retry } );
        Idle.add( checkRestartingQ );
    }

    public async string[] enqueueAsyncYielding( AtCommand command, string request, uint retry = DEFAULT_RETRY )
    {
        logger.debug( "enqueuing %s from AT command %s (sizeof q = %u)".printf( request, Type.from_instance( command ).name(), q.size ) );
        var retriggerWriting = ( q.size == 0 );
        CommandBundle bundle = new CommandBundle() {
            command=command,
            request=request,
            getRequest=null,
            callback=enqueueAsyncYielding.callback,
            retry=retry };
        q.offer_tail( bundle );
        Idle.add( checkRestartingQ );
        yield;
        return bundle.response;
    }

    public void deferred( AtCommand command, RequestHandler getRequest, ResponseHandler? handler = null, uint retry = DEFAULT_RETRY )
    {
        logger.debug( "enqueuing deferred request %s".printf( getRequest( command ) ) );
        var retriggerWriting = ( q.size == 0 );
        q.offer_tail( new CommandBundle() {
            command=command,
            request=null,
            getRequest=getRequest,
            handler=handler,
            retry=retry } );
        Idle.add( checkRestartingQ );
    }

    protected bool checkRestartingQ()
    {
        if ( current == null && q.size > 0 )
        {
            writeNextCommand();
            return true;
        }
        else
        {
            return false;
        }
    }

    public bool open()
    {
        // open transport
        assert( !transport.isOpen() );
        if ( !transport.open() )
            return false;
        else
            return true;
        //TODO: more initialization necessary?
    }

    public void freeze( bool drain = false )
    {
        assert_not_reached();
    }

    public void thaw()
    {
        assert_not_reached();
    }

    public void close()
    {
        transport.close();
    }
}
