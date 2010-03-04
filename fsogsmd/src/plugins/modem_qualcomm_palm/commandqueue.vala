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

public class MsmCommandBundle
{
    public Msmcomm.Message command;
    public uint retry;
    public unowned Msmcomm.Message response;
    public SourceFunc callback;
}

public class MsmCommandQueue : FsoFramework.CommandQueue, GLib.Object
{
    // don't access this unless absolutely necessary
    public FsoFramework.Transport transport;

    protected Gee.LinkedList<MsmCommandBundle> q;
    protected MsmCommandBundle current;
    protected uint timeout;

    protected Msmcomm.Context context;

    protected void _writeRequestToTransport( string request )
    {
        assert( current != null );

        /*
        if ( seconds > 0 )
        {
            timeout = Timeout.add_seconds( seconds, _onTimeout );
        }
        */
    }

    protected void _onReadFromTransport( FsoFramework.Transport t )
    {
        if ( timeout > 0 )
        {
            Source.remove( timeout );
        }

        context.readFromModem();

        /*
        var bytesread = transport.read( buffer, COMMAND_QUEUE_BUFFER_SIZE );
        buffer[bytesread] = 0;
        onReadFromTransport( (string)buffer );
        */
    }

    protected void _onHupFromTransport( FsoFramework.Transport t )
    {
        // HUP
    }

    protected bool _onTimeout()
    {
        // TIMEOUT
        return false;
    }

    protected bool _haveCommand()
    {
        return ( current != null );
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
        var size = message.size;
        var m = "ref %02x".printf( message.getRefId() );
        debug( @"[MESSAGE] $et $m " );
        var details = "";

        switch ( event )
        {
            case Msmcomm.ResponseType.GET_IMEI:
                debug("yo");
                unowned Msmcomm.Reply.GetImei msg = (Msmcomm.Reply.GetImei) message;
                details = @"IMEI = $(msg.getImei())";
                break;
            case Msmcomm.ResponseType.GET_FIRMWARE_INFO:
                // We want something like: var msg = message.safeCast<Msmcomm.Reply.GetImei>( message );
                unowned Msmcomm.Reply.GetFirmwareInfo msg = (Msmcomm.Reply.GetFirmwareInfo) message;
                details = @"FIRMWARE = $(msg.getInfo())";
                break;
            case Msmcomm.ResponseType.CM_CALL:
                unowned Msmcomm.Reply.Call msg = (Msmcomm.Reply.Call) message;
                details = @"refId = $(msg.getRefId()) cmd = $(msg.getCmd()) err = $(msg.getErrorCode())";
                break;
            case Msmcomm.ResponseType.CHARGER_STATUS:
                unowned Msmcomm.Reply.ChargerStatus msg = (Msmcomm.Reply.ChargerStatus) message;
                string mode = "<unknown>", voltage = "<unknown>";
            
                if (msg.getMode() == Msmcomm.ChargingMode.USB)
                    mode = "USB";
                else if (msg.getMode() == Msmcomm.ChargingMode.INDUCTIVE)
                    mode = "INDUCTIVE";

                switch (msg.getVoltage()) {
                case Msmcomm.UsbVoltageMode.MODE_250mA:
                    voltage = "250mA";
                    break;
                case Msmcomm.UsbVoltageMode.MODE_500mA:
                    voltage = "500mA";
                    break;
                case Msmcomm.UsbVoltageMode.MODE_1A:
                    voltage = "1A";
                    break;
                }

                details = @"mode = $(mode) voltage = $(voltage)";
                break;
            default:
                break;
        }

        debug( @"$details" );

        if ( et.has_prefix( "RESPONSE" ) )
        {
            assert( current != null );
            onSolicitedResponse( current, message );
            current = null;
            Idle.add( checkRestartingQ );
        }
        else
        {
            debug( @"FIXME: CREATE URC HANDLER FOR MSM COMMAND $et" );
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
        // send command via msm transport
    }

    protected void onSolicitedResponse( MsmCommandBundle bundle, Msmcomm.Message response )
    {
        //transport.logger.info( "SRC: \"%s\" -> %s".printf( bundle.request, FsoFramework.StringHandling.stringListToString( response ) ) );

        if ( bundle.callback != null )
        {
            bundle.response = response;
            bundle.callback();
        }
    }

    //
    // public API
    //

    public MsmCommandQueue( FsoFramework.Transport transport )
    {
        context = new Msmcomm.Context();
        q = new Gee.LinkedList<MsmCommandBundle>();
        this.transport = transport;
        transport.setDelegates( _onReadFromTransport, _onHupFromTransport );
    }

    ~MsmCommandQueue()
    {
    }

    public void registerUnsolicitedHandler( FsoFramework.CommandQueue.UnsolicitedHandler urchandler )
    {
    }

    public async string[] enqueueAsyncYielding( FsoFramework.CommandQueueCommand command, string request, uint retry = DEFAULT_RETRY )
    {
        return {};
    }

    public async unowned Msmcomm.Message processMsmCommand( Msmcomm.Message* command )
    {
        MsmCommandBundle bundle = new MsmCommandBundle() {
            command=(owned)command,
            callback=processMsmCommand.callback,
            retry=3 };
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
        {
            return false;
        }
        else
        {
            context.registerEventHandler( onMsmcommGotEvent );
            context.registerReadHandler( onMsmcommShouldRead );
            context.registerWriteHandler( onMsmcommShouldWrite );

            var cmd = new Msmcomm.Command.ChangeOperationMode();
            cmd.setOperationMode( Msmcomm.OperationMode.RESET );
            context.sendMessage( cmd );

            return true;
        }
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
