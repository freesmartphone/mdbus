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

public delegate void FsoGsm.UnsolicitedHandler( FsoGsm.AtCommand command, string response );
public delegate void FsoGsm.UnsolicitedHandlerPDU( FsoGsm.AtCommand command, string response, string pdu );

const uint COMMAND_QUEUE_CHANNEL_TIMEOUT = 10;
const uint COMMAND_QUEUE_DEFAULT_RETRY = 3;
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

[Compact]
public class FsoGsm.UnsolicitedBundle
{
    public FsoGsm.AtCommand command;
    public string prefix;
    public UnsolicitedHandler handler;
}

[Compact]
public class FsoGsm.UnsolicitedBundlePDU
{
    public FsoGsm.AtCommand command;
    public string prefix;
    public UnsolicitedHandlerPDU handler;
}

public abstract interface FsoGsm.CommandQueue : Object
{
    /**
     * Enqueue new @a AtCommand command, sending the request as @a string request.
     * Coroutine will yield the response.
     **/
    public abstract async string[] enqueueAsyncYielding( AtCommand command, string request, uint retry = COMMAND_QUEUE_DEFAULT_RETRY );
    /**
     * Enqueue new @a AtCommand command, sending the request as @a string request.
     * The @a SourceFunc callback will be called. The response from the peer is set in the command bundle.
     **/
    public abstract void enqueueAsync( AtCommand command, string request, SourceFunc? callback = null, string[]? response = null, uint retry = COMMAND_QUEUE_DEFAULT_RETRY );
    /**
     * Enqueue new @a AtCommand command, sending the request as @a string request.
     * The @a ResponseHandler handler will be called with the response from the peer.
     **/
    public abstract void enqueue( AtCommand command, string request, ResponseHandler? handler = null, uint retry = COMMAND_QUEUE_DEFAULT_RETRY );
    /**
     * Enqueue new @a AtCommand command. When the command is due for sending, the
     * @a RequestHandler getRequest will be called to gather the request string.
     **/
    public abstract void deferred( AtCommand command, RequestHandler getRequest, ResponseHandler? handler = null, uint retry = COMMAND_QUEUE_DEFAULT_RETRY );
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

    protected HashTable<string, FsoGsm.UnsolicitedBundle> urcs;
    protected HashTable<string, FsoGsm.UnsolicitedBundlePDU> urcs_pdu;

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
        onResponseFromTransport( (string)buffer );
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
        logger.debug( "solicited completed: %s".printf( FsoFramework.StringHandling.stringListToString( response ) ) );
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
            weak UnsolicitedBundle bundle = urcs.lookup( strings[0] );

            if ( bundle == null )
                logger.warning( "unregistered URC. Please report!" );
            else
                bundle.handler( bundle.command, strings[1] );
        }
        else if ( response.length == 2 ) // PDU URC
        {
            weak UnsolicitedBundlePDU bundle = urcs_pdu.lookup( strings[0] );

            if ( bundle == null )
                logger.warning( "unregistered URC w/ PDU. Please report!" );
            else
                bundle.handler( bundle.command, strings[1], response[1] );
        }
        else
            assert_not_reached();
    }

    //=====================================================================//
    // SUBCLASSING API
    //=====================================================================//

    protected void writeNextCommand()
    {
        logger.debug( "writing next command" );
        current = q.poll_head();
        _writeRequestToTransport( current.request );
    }

    protected void onResponseFromTransport( string response )
    {
        logger.debug( "response = %s".printf( response.escape( "" ) ) );
        parser.feed( response, (int)response.length );
    }

    protected void onHupFromTransport()
    {
        logger.debug( "hup from transport. closing." );
        transport.close();
    }

    protected void onSolicitedResponse( CommandBundle bundle, string[] response )
    {
        debug( "on solicited response w/ %d lines", response.length );
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
        urcs = new HashTable<string, FsoGsm.UnsolicitedBundle>( str_hash, str_equal );
        urcs_pdu = new HashTable<string, FsoGsm.UnsolicitedBundlePDU>( str_hash, str_equal );
    }

    ~AtCommandQueue()
    {
        free( buffer );
    }

    public override string repr()
    {
        return "<Unnamed AtCommandQueue>";
    }

    public void registerUnsolicited( AtCommand command, string prefix, UnsolicitedHandler handler )
    {
        logger.debug( "registering unsolicited handler for prefix '%s'".printf( prefix ) );
        assert( urcs.lookup( prefix ) == null ); // not allowed to register twice for one prefix
        urcs.insert( prefix, new UnsolicitedBundle() { command=command, prefix=prefix, handler=handler } );
    }

    public void registerUnsolicitedPDU( AtCommand command, string prefix, UnsolicitedHandlerPDU handler )
    {
        logger.debug( "registering unsolicited PDU handler for prefix '%s'".printf( prefix ) );
        assert( urcs_pdu.lookup( prefix ) == null ); // not allowed to register twice for one prefix
        urcs_pdu.insert( prefix, new UnsolicitedBundlePDU() { command=command, prefix=prefix, handler=handler } );
    }

    public void enqueue( AtCommand command, string request, ResponseHandler? handler = null, uint retry = COMMAND_QUEUE_DEFAULT_RETRY )
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

    public void enqueueAsync( AtCommand command, string request, SourceFunc? callback = null, string[]? response = null, uint retry = COMMAND_QUEUE_DEFAULT_RETRY )
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

    public async string[] enqueueAsyncYielding( AtCommand command, string request, uint retry = COMMAND_QUEUE_DEFAULT_RETRY )
    {
        logger.debug( "enqueuing %s (sizeof q = %u)".printf( request, q.size ) );
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

    public void deferred( AtCommand command, RequestHandler getRequest, ResponseHandler? handler = null, uint retry = COMMAND_QUEUE_DEFAULT_RETRY )
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

}

