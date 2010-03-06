/**
 * Copyright (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

/**
 * @class FsoGsm.AtCommandHandler
 **/
public class FsoGsm.AtCommandHandler : FsoFramework.AbstractCommandHandler
{
    public FsoFramework.CommandQueueCommand command;
    private string request;
    public string[] response;

    public AtCommandHandler( FsoFramework.CommandQueueCommand command, string request, int retries )
    {
        this.command = command;
        this.request = request;
        this.retry = retries;
    }

    public override void writeToTransport( FsoFramework.Transport transport )
    {
        var prefix = command.get_prefix();
        var postfix = command.get_postfix();

        if ( prefix.length > 0 )
        {
            transport.write( prefix, (int)prefix.length );
        }
        if ( request.size() > 0 )
        {
            transport.write( request, (int)request.size() );
        }
        if ( postfix.length > 0 )
        {
            transport.write( postfix, (int)postfix.length );
        }
    }

    public override string to_string()
    {
        if ( response != null )
        {
            return "\"%s\" -> %s".printf( request, FsoFramework.StringHandling.stringListToString( response ) );
        }
        else
        {
            return request;
        }
    }


}

/**
 * @class FsoGsm.AtCommandQueue
 **/
public class FsoGsm.AtCommandQueue : FsoFramework.AbstractCommandQueue
{
    public const int COMMAND_QUEUE_BUFFER_SIZE = 4096;

    protected char* buffer;
    protected FsoFramework.Parser parser;

    public AtCommandQueue( FsoFramework.Transport transport, FsoFramework.Parser parser )
    {
        base( transport );
        this.parser = parser;
        parser.setDelegates( haveCommand, isExpectedPrefix, onParserCompletedSolicited, onParserCompletedUnsolicited );
        buffer = malloc( COMMAND_QUEUE_BUFFER_SIZE );
    }

    protected override void onReadFromTransport( FsoFramework.Transport t )
    {
        var bytesread = transport.read( buffer, COMMAND_QUEUE_BUFFER_SIZE );

        if ( bytesread == 0 )
        {
            onHupFromTransport();
            return;
        }

        buffer[bytesread] = 0;
#if DEBUG
        debug( "Read '%s' - feeding to %s".printf( ((string)response).escape( "" ), Type.from_instance( parser ).name() ) );
#endif
        parser.feed( (string)buffer, bytesread );
    }

    protected bool haveCommand()
    {
        return ( current != null );
    }

    protected bool isExpectedPrefix( string line )
    {
        assert( current != null );
        return ((AtCommandHandler)current).command.is_valid_prefix( line );
    }

    protected void onParserCompletedSolicited( string[] response )
    {
        assert( current != null );
        onSolicitedResponse( (AtCommandHandler)current, response );
        current = null;
        Idle.add( checkRestartingQ );
    }

    protected void onParserCompletedUnsolicited( string[] response )
    {
        assert_not_reached();
        /*
        transport.logger.info( "URC: %s".printf( FsoFramework.StringHandling.stringListToString( response ) ) );

        //TODO: should we have a configurable prefix separator or is that over the top?

        if ( ! ( ":" in response[0] ) ) // test for free-form URC
        {
            urchandler( response[0], "", null );
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
        */
    }

    protected void onSolicitedResponse( AtCommandHandler bundle, string[] response )
    {
        bundle.response = response;
        transport.logger.info( @"SRC: $bundle" );
        assert( bundle.callback != null );
        bundle.callback();
    }

    protected void onResponseTimeout( AtCommandHandler bundle )
    {
        onSolicitedResponse( bundle, new string[] { "+EXT: ERROR 261271" } );
    }

    public async string[] enqueueAsync( FsoFramework.CommandQueueCommand command, string request, int retries = DEFAULT_RETRY )
    {
#if DEBUG
        debug( "enqueuing %s from AT command %s (sizeof q = %u)".printf( request, Type.from_instance( command ).name(), q.size ) );
#endif
        var handler = new AtCommandHandler( command, request, retries );
        handler.callback = enqueueAsync.callback;
        enqueueCommand( handler );
        yield;
        return handler.response;
    }
}

/**
 * @class AtCommandSequence
 **/
public class FsoGsm.AtCommandSequence
{
    private string[] commands;

    public AtCommandSequence( string[] commands )
    {
        this.commands = commands;
    }

    public void append( string[] commands )
    {
        foreach ( var cmd in commands )
        {
            this.commands += cmd;
        }
    }

    public async void performOnChannel( AtChannel channel )
    {
        foreach( var element in commands )
        {
            var cmd = theModem.createAtCommand<CustomAtCommand>( "CUSTOM" );
            var response = yield channel.enqueueAsync( cmd, element );
        }
    }
}
