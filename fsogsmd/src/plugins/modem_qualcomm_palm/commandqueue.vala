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

    // FIXME: This bypasses the generic URChandler idea in the base modem class,
    // however said URChandler is unfortunately not generic at all, but very
    // text-format specific. Will change this after 1.0...
    private MsmUnsolicitedResponseHandler msmurchandler;

    protected override void onReadFromTransport( FsoFramework.Transport t )
    {
        context.readFromModem();
    }

    protected void onSolicitedResponse( MsmCommandHandler bundle, Msmcomm.Message response )
    {
        bundle.response = response;
        transport.logger.info( @"SRC: $bundle" );
        assert( bundle.callback != null );
        bundle.callback();
    }

    protected void onUnsolicitedResponse( Msmcomm.EventType urctype, Msmcomm.Message urc )
    {
        if ( msmurchandler == null )
        {
            msmurchandler = new MsmUnsolicitedResponseHandler();
        }
        msmurchandler.dispatch( urctype, urc );
    }

    public async unowned Msmcomm.Message enqueueAsync( owned Msmcomm.Message command, int retries = DEFAULT_RETRY )
    {
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
        // enable when glib bug for unknown types has been fixed
        //assert( transport.logger.debug( @"$message" ) );
        var et = Msmcomm.eventTypeToString( event );
        assert( et != null );
        //transport.logger.debug( et );

        // FIXME: We're treating some URCs as responses here :/
        if ( et.has_prefix( "RESPONSE" ) || et.has_prefix( "URC_RESET_RADIO_IND" ) )
        {
            assert( current != null );
            onSolicitedResponse( (MsmCommandHandler)current, message );
            current = null;
            Idle.add( checkRestartingQ );
        }
        else
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
        context = new Msmcomm.Context();
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
