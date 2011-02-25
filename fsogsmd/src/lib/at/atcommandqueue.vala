/*
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 */

/**
 * @class FsoFramework.AtCommandQueueCommand
 **/
public abstract interface FsoGsm.AtCommandQueueCommand : GLib.Object
{
    public abstract uint get_retry();
    public abstract uint get_timeout();
    public abstract string get_prefix();
    public abstract string get_postfix();
    public abstract bool is_valid_prefix( string line );
}

/**
 * @class FsoGsm.AtCommandHandler
 **/
public class FsoGsm.AtCommandHandler : FsoFramework.AbstractCommandHandler
{
    public FsoGsm.AtCommandQueueCommand command;
    private string request;
    public string[] response;

    public AtCommandHandler( FsoGsm.AtCommandQueueCommand command, string request, uint retries = 0, uint timeout = 0 )
    {
        this.command = command;
        this.request = request;
        this.retry = retries > 0 ? retries : command.get_retry();
        this.timeout = timeout > 0 ? timeout : command.get_timeout();
    }

    public override void writeToTransport( FsoFramework.Transport transport )
    {
        var prefix = command.get_prefix();
        var postfix = command.get_postfix();

        if ( prefix.length > 0 )
        {
            transport.write( prefix, (int)prefix.length );
        }
        if ( request.length > 0 )
        {
            transport.write( request, (int)request.length );
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
            return;
        }

        buffer[bytesread] = 0;
#if DEBUG
        debug( "Read '%s' - feeding to %s".printf( ((string)buffer).escape( "" ), Type.from_instance( parser ).name() ) );
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
        transport.logger.info( "URC: %s".printf( FsoFramework.StringHandling.stringListToString( response ) ) );

        if ( ! ( ":" in response[0] ) ) // test for free-form URC
        {
            urchandler( response[0], "", null );
            return;
        }

        // AT URCs have the form PREFIX:SUFFIX
        var strings = response[0].split( ":", 2 );

        if ( response.length == 1 ) // simple URCs
        {
            urchandler( strings[0], strings[1].strip() );
        }
        else if ( response.length == 2 ) // PDU URC
        {
            urchandler( strings[0], strings[1].strip(), response[1] );
        }
        else
        {
            transport.logger.critical( @"Can't handle URC w/ $(response.length) lines (max 2) yet!" );
        }
    }

    protected void onSolicitedResponse( AtCommandHandler bundle, string[] response )
    {
        resetTimeout();

        bundle.response = response;
        transport.logger.info( @"SRC: $bundle" );
        assert( bundle.callback != null );
        bundle.callback();
    }

    protected override void onResponseTimeout( FsoFramework.AbstractCommandHandler bundle )
    {
        onSolicitedResponse( (AtCommandHandler) bundle, new string[] { @"+EXT: TIMEOUT $(bundle.timeout)" } );
    }

    public async string[] enqueueAsync( FsoGsm.AtCommandQueueCommand command, string request, int retries = 0, int timeout = 0 )
    {
#if DEBUG
        debug( "enqueuing %s from AT command %s".printf( request, Type.from_instance( command ).name() ) );
#endif
        var handler = new AtCommandHandler( command, request, retries, timeout );
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
            var components = element.split( "=" );

            var cmd = new FsoGsm.CustomAtCommand( components[0] );
            /* var result = */ yield channel.enqueueAsync( cmd, element );
            // no error checks here as we don't care about the result
        }
    }
}
