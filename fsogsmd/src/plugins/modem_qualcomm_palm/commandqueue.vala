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
    public Msmcomm.Message response;
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

    public void onMsmcommGotEvent( int event, Msmcomm.Message? message )
    {
        var et = Msmcomm.eventTypeToString( event );
        var m = "ref %02x".printf( message.getRefId() );
        debug( @"[MESSAGE] $et $m " );
        var details = "";

        switch ( event )
        {
            case Msmcomm.ResponseType.GET_IMEI:
                unowned Msmcomm.Response.GetImei msg = (Msmcomm.Response.GetImei) message;
                details = @"IMEI = $(msg.getImei())";
                break;
            case Msmcomm.ResponseType.GET_FIRMWARE_INFO:
                // We want something like: var msg = message.safeCast<Msmcomm.Response.GetImei>( message );
                unowned Msmcomm.Response.GetFirmwareInfo msg = (Msmcomm.Response.GetFirmwareInfo) message;
                details = @"FIRMWARE = $(msg.getInfo())";
                break;
            case Msmcomm.ResponseType.CM_CALL:
                unowned Msmcomm.Response.Call msg = (Msmcomm.Response.Call) message;
                details = @"refId = $(msg.getRefId()) cmd = $(msg.getCmd()) err = $(msg.getErrorCode())";
                break;
            case Msmcomm.ResponseType.CHARGER_STATUS:
                unowned Msmcomm.Response.ChargerStatus msg = (Msmcomm.Response.ChargerStatus) message;
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

        debug( @"$details\n" );
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

    public async Msmcomm.Message processMsmCommand( Msmcomm.Message* command )
    {
        assert_not_reached();
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
