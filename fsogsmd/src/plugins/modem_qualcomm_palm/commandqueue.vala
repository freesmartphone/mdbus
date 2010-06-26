/*
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
 * @class MsmCommandHandler
 **/
public class MsmCommandHandler : FsoFramework.AbstractCommandHandler
{
    public unowned Msmcomm.Message command;
    public unowned Msmcomm.Message response;

    public MsmCommandHandler( Msmcomm.Message command, int retries )
    {
        this.command = command;
        this.retry = retries;
    }

    public override void writeToTransport( FsoFramework.Transport transport )
    {
        MsmCommandQueue.context.sendMessage( command );
    }

    public override string to_string()
    {
        if ( response != null )
        {
            return "\"%s\" -> %s".printf( Msmcomm.eventTypeToString( command.type ), Msmcomm.eventTypeToString( response.type ) );
        }
        else
        {
            return Msmcomm.eventTypeToString( command.type );
        }
    }
}

/**
 * @class MsmCommandQueue
 **/
public class MsmCommandQueue : FsoFramework.AbstractCommandQueue
{
    public static Msmcomm.Context context;
    public static MsmUnsolicitedResponseHandler msmurchandler;
    public uint32 current_index;

    // FIXME: This bypasses the generic URChandler idea in the base modem class,
    // however said URChandler is unfortunately not generic at all, but very
    // text-format specific. Will change this after 1.0...

    protected override void onReadFromTransport( FsoFramework.Transport t )
    {
        context.readFromModem();
    }
    
    private bool checkResponseForCommandHandler(Msmcomm.Message response, MsmCommandHandler bundle)
    {
        return response.index == bundle.command.index;
    }
    
    private uint32 nextValidMessageIndex()
    {
        if (current_index > uint32.MAX) {
            current_index = 0;
        }
        else {
            current_index++;
        }
        return current_index;
    }

    protected void onSolicitedResponse( MsmCommandHandler bundle, Msmcomm.Message response )
    {
        if ( checkResponseForCommandHandler( response, bundle ) )
        {
            bundle.response = response;
            transport.logger.info( @"SRC: $bundle" );
            assert( bundle.callback != null );
            bundle.callback();
        }
        else 
        {
            transport.logger.error( @"got response for current command with wrong ref id!" );
        }
    }

    protected void onUnsolicitedResponse( Msmcomm.EventType urctype, Msmcomm.Message urc )
    {
        msmurchandler.dispatch( urctype, urc );
    }

    public async unowned Msmcomm.Message enqueueAsync( owned Msmcomm.Message command, int retries = DEFAULT_RETRY )
    {
        command.index = nextValidMessageIndex();
        var handler = new MsmCommandHandler( command, retries );
        handler.callback = enqueueAsync.callback;
        enqueueCommand( handler );
        yield;
        return handler.response;
    }

    public void onMsmcommShouldRead( void* data, int len )
    {
        var bread = transport.read( data, len );
    }

    public void onMsmcommShouldWrite( void* data, int len )
    {
        var bwritten = transport.write( data, len );
        assert( bwritten == len );
    }

    public void onMsmcommGotEvent( int event, Msmcomm.Message message )
    {
        var et = Msmcomm.eventTypeToString( event );
        transport.logger.debug( et );

        if ( message.type == Msmcomm.EventType.RESET_RADIO_IND )
        {
            /* Modem was reseted, we should do the same */
            reset();
        }
        else if ( message.message_type == Msmcomm.MessageType.RESPONSE )
        {
            assert( current != null );
            onSolicitedResponse( (MsmCommandHandler)current, message );
            current = null;
            Idle.add( checkRestartingQ );
        }
        else if ( message.message_type == Msmcomm.MessageType.EVENT )
        {
            onUnsolicitedResponse( (Msmcomm.EventType) event, message );
        }
    }

    //
    // public API
    //
    public MsmCommandQueue( FsoFramework.Transport transport )
    {
        base( transport );
        current_index = 0;
        context = new Msmcomm.Context();
        msmurchandler = new MsmUnsolicitedResponseHandler();
    }

    public override async bool open()
    {
        // FIXME: yield base.open() does not work in Vala atm.

        // open transport
        assert( !transport.isOpen() );
        var opened = yield transport.openAsync();

        if ( opened /* yield base.open() */ )
        {
            context.registerEventHandler( onMsmcommGotEvent );
            context.registerReadHandler( onMsmcommShouldRead );
            context.registerWriteHandler( onMsmcommShouldWrite );

            return true;
        }

        return false;
    }
}

/**
 * @class MsmCommandSequence
 **/
public class MsmCommandSequence
{
    /*
    private string[] commands;

    public MsmCommandSequence( string[] commands )
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
            var cmd = theModem.createMsmCommand<CustomMsmCommand>( "CUSTOM" );
            var response = yield channel.enqueueAsync( cmd, element );
        }
    }
    */
}
