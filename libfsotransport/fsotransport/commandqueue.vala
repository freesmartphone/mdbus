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

const int  COMMAND_QUEUE_BUFFER_SIZE = 4096;

public abstract interface FsoFramework.CommandQueueCommand : GLib.Object
{
    public abstract uint get_retry();
    public abstract uint get_timeout();
    public abstract string get_prefix();
    public abstract string get_postfix();
    public abstract bool is_valid_prefix( string line );
}

public abstract interface FsoFramework.CommandQueue : GLib.Object
{
    public delegate void ResponseHandler( CommandQueueCommand command, string[] response );
    public delegate string RequestHandler( CommandQueueCommand command );
    public delegate void UnsolicitedHandler( string prefix, string response, string? pdu = null );

    public const uint DEFAULT_RETRY = 3;
    /**
     * Register @a UnsolicitedHandler delegate that will be called for incoming URCs
     **/
    public abstract void registerUnsolicitedHandler( UnsolicitedHandler urchandler );
    /**
     * Enqueue new @a AtCommand command, sending the request as @a string request.
     * Coroutine will yield the response.
     **/
    public abstract async string[] enqueueAsyncYielding( CommandQueueCommand command, string request, uint retry = DEFAULT_RETRY );
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

public class CommandBundle
{
    public FsoFramework.CommandQueueCommand command;
    public string request;
    public uint retry;
    public FsoFramework.CommandQueue.RequestHandler getRequest;
    public FsoFramework.CommandQueue.ResponseHandler handler;
    public string[] response;
    public SourceFunc callback;
}

public class FsoFramework.BaseCommandQueue : FsoFramework.CommandQueue, GLib.Object
{
    protected Gee.LinkedList<CommandBundle> q;
    protected CommandBundle current;
    protected uint timeout;

    protected Transport transport;
    protected Parser parser;
    protected char* buffer;
    protected FsoFramework.CommandQueue.UnsolicitedHandler urchandler;

    protected void _writeRequestToTransport( string request )
    {
        assert( current != null );

        var prefix = current.command.get_prefix();
        var postfix = current.command.get_postfix();
        var seconds = current.command.get_timeout();

        transport.write( prefix, (int)prefix.length );
        transport.write( request, (int)request.size() );
        transport.write( postfix, (int)postfix.length );
        if ( seconds > 0 )
        {
            timeout = Timeout.add_seconds( seconds, _onTimeout );
        }
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
            transport.logger.warning( @"Transport did not reply to command '$(current.request)'. Resending..." );
            _writeRequestToTransport( current.request );
        }
        else
        {
            transport.logger.error( @"Transport did (even after retrying) not reply to command '$(current.request)'" );

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
        assert( current != null );
        return current.command.is_valid_prefix( line );
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
        transport.logger.info( "URC: %s".printf( FsoFramework.StringHandling.stringListToString( response ) ) );

        //TODO: should we have a configurable prefix separator or is that over the top?

        if ( ! ( ":" in response[0] ) ) // test for free-form URC
        {
            urchandler( "", response[0], "" );
            return;
        }

        // URC has the form PREFIX:SUFFIX
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
            transport.logger.critical( @"Can't handle URC w/ $(response.length) lines (max 2) yet!" );
        }
    }

    //
    // subclassing API
    //

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

    protected void writeNextCommand()
    {
        current = q.poll_head();
        _writeRequestToTransport( current.request );
        assert( transport.logger.debug( @"Wrote '$(current.request)' to transport. Waiting for answer..." ) );
    }

    protected void onReadFromTransport( string response )
    {
        if ( response.length > 0 )
        {
#if DEBUG
            debug( "Read '%s' - feeding to %s".printf( response.escape( "" ), Type.from_instance( parser ).name() ) );
#endif
            parser.feed( response, (int)response.length );
        }
        else
        {
            onHupFromTransport();
        }
    }

    protected void onHupFromTransport()
    {
        transport.logger.warning( "HUP from transport. closing." );
        transport.close();
        //FIXME: Try to open again or leave that to the higher layers?
    }

    protected void onSolicitedResponse( CommandBundle bundle, string[] response )
    {
        transport.logger.info( "SRC: \"%s\" -> %s".printf( bundle.request, FsoFramework.StringHandling.stringListToString( response ) ) );

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

    //
    // public API
    //

    public BaseCommandQueue( Transport transport, Parser parser )
    {
        q = new Gee.LinkedList<CommandBundle>();
        this.transport = transport;
        this.parser = parser;
        transport.setDelegates( _onReadFromTransport, _onHupFromTransport );
        parser.setDelegates( _haveCommand, _expectedPrefix, _solicitedCompleted, _unsolicitedCompleted );

        buffer = malloc( COMMAND_QUEUE_BUFFER_SIZE );
    }

    ~BaseCommandQueue()
    {
        free( buffer );
    }

    public void registerUnsolicitedHandler( FsoFramework.CommandQueue.UnsolicitedHandler urchandler )
    {
        assert( this.urchandler == null );
        this.urchandler = urchandler;
    }

    public async string[] enqueueAsyncYielding( CommandQueueCommand command, string request, uint retry = DEFAULT_RETRY )
    {
#if DEBUG
        debug( "enqueuing %s from AT command %s (sizeof q = %u)".printf( request, Type.from_instance( command ).name(), q.size ) );
#endif
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
