/*
 * Copyright (C) 2011 Simon Busch <morphis@gravedo.de>
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

using GLib;
using FsoGsm;
using FsoFramework;

public class Samsung.IpcChannel : FsoGsm.Channel, FsoFramework.AbstractCommandQueue
{
    private SamsungIpc.Client fmtclient;
    private uint8 current_request_id = 1;
    private bool initialized = false;
    private bool suspended = false;
    private FsoFramework.Wakelock wakelock;
    private FreeSmartphone.UsageSync usage_sync;
    private uint suspend_lock = 0;
    private FsoGsm.Modem.Status current_modem_status = FsoGsm.Modem.Status.UNKNOWN;
    private FsoGsm.Modem modem;

    public new Samsung.UnsolicitedResponseHandler urchandler { get; private set; }
    public string name { get; private set; }
    public SamsungIpc.Power.PhoneState phone_pwr_state { get; private set; default = SamsungIpc.Power.PhoneState.LPM; }

    public delegate void UnsolicitedHandler( string prefix, string response, string? pdu = null );

    /**
     * Generating a new request id. A valid request is in the range of 1 - 255.
     **/
    private uint8 next_request_id()
    {
        current_request_id = current_request_id >= 255 ? 1 : current_request_id + 1;
        return current_request_id;
    }

    private void onModemStatusChanged( FsoGsm.Modem modem, FsoGsm.Modem.Status status )
    {
        switch ( status )
        {
            case FsoGsm.Modem.Status.INITIALIZING:
                initialize();
                break;
            case FsoGsm.Modem.Status.ALIVE_SIM_READY:
                if ( current_modem_status == FsoGsm.Modem.Status.ALIVE_REGISTERED )
                {
                    ModemState.reset_network_data();
                    // Force update of the signal strength for all connected clients
                    var obj = modem.theDevice<FreeSmartphone.GSM.Network>();
                    obj.signal_strength( ModemState.network_signal_strength );
                }
                break;
            default:
                break;
        }

        current_modem_status = status;
    }

    protected override void onReadFromTransport( FsoFramework.Transport t )
    {
        SamsungIpc.Response response = SamsungIpc.Response();

        wakelock.acquire();

        assert( theLogger.debug( @"Received data from modem; start processing ..." ) );

        var rc = fmtclient.recv(out response);
        if ( rc != 0 )
        {
            theLogger.error( @"Something went wrong while receiving data from the modem ... discarding this request!" );
            return;
        }

        assert( theLogger.debug( @"Got response from modem: type = $(response.type), command = $(response.command)" ) );
        assert( theLogger.debug( @"response data (length = $(response.data.length)):" ) );
        assert( theLogger.debug( "\n" + FsoFramework.StringHandling.hexdump( response.data ) ) );

        if ( suspended )
        {
            // NOTE the following steps we be all done in-sync as we don't need to be
            // async here cause it's the most important thing now to check if we got some
            // message we should take as indicator to wake up completely and nothing else!
            handle_response_in_suspend_mode( response );
            wakelock.release();
            return;
        }

        switch ( response.type )
        {
            case SamsungIpc.ResponseType.NOTI:
                urchandler.process( response );
                break;
            case SamsungIpc.ResponseType.INDI:
                break;
            case SamsungIpc.ResponseType.RESP:
                handle_solicited_response( response );
                break;
        }

        // libsamsung-ipc allocates some memory for the response data which is not being
        // freed otherwise
        free(response.data);

        assert( theLogger.debug( @"Handled response from modem successfully!" ) );

        wakelock.release();
    }

    /**
     * When the system is suspended and we're running a kernel with android extensions
     * things are a bit ... what should I say: different :)
     * The usage subsystem disables all resources but each resource can decide on it's own
     * if it accepts the the suspend action internally.
     * In our case we're disabling as much as possible but still watching for incoming
     * messages from the modem. If the modems sends a notification for an incoming call
     * we will wake up the system first and then process the message.
     **/
    private void handle_response_in_suspend_mode( SamsungIpc.Response response )
    {
        assert( theLogger.debug( @"Got message from modem while in suspend mode: type = $(response.type), command = $(response.command)" ) );

        if ( response.type == SamsungIpc.ResponseType.NOTI )
        {
            switch ( response.command )
            {
                case SamsungIpc.MessageType.CALL_INCOMING:
                    assert( theLogger.debug( @"Got notification for incoming call; leaving suspend ..." ) );
                    // FIXME supply correct usage resume reason here so the usage daemon
                    // can figure out the correct one for the modem.
                    wakeup_system( "incoming-call" );
                    urchandler.process( response );
                    break;
                default:
                    assert( theLogger.debug( @"Got $(response.command) urc which is not evaluated while we're suspended" ) );
                    break;
            }
        }
    }

    /**
     * Waking up the system from suspend or alive state to fully awake we need to run
     * several steps like telling the usage subsystem to resume all suspended resources.
     * When this method returns the system should be completely awake.
     */
    private void wakeup_system( string reason )
    {
        try
        {
            usage_sync.resume( "Modem", reason );
        }
        catch ( GLib.Error err )
        {
            theLogger.error( @"Can't wake up the system; assuming we're already alive: $(err.message)" );
        }
    }

    private void handle_solicited_response( SamsungIpc.Response response )
    {
        resetTimeout();

        var ch  = (Samsung.CommandHandler) current;

        if ( current == null || ch.id != response.aseq )
        {
            theLogger.error( @"Got response with id = $(response.aseq) which does not belong to any pending request!" );
            return;
        }

        ch.response = response;
        ch.callback();
    }

    protected override void onResponseTimeout( AbstractCommandHandler ach )
    {
        Samsung.CommandHandler handler = (Samsung.CommandHandler) ach;

        theLogger.warning( @"Command with id = $(handler.id) timed out while trying to send it to the modem!" );
        handler.timed_out = true;

        // We're just telling the user about this as he will not receive any
        // response message for his enqueue_async call.
        Idle.add( () => { handler.callback(); return false; } );
    }

    protected int modem_read_request(uint8[] data)
    {
        if ( data == null  )
            return 0;

        return transport.read(data, data.length);
    }

    protected int modem_write_request(uint8[] data)
    {
        if ( data == null )
            return 0;

        return transport.write(data, data.length);
    }

    private async void initialize()
    {
        initialized = yield set_modem_power_state( SamsungIpc.Power.PhoneState.LPM );
    }

    private async void request_usage_service()
    {
        try
        {
            usage_sync = yield Bus.get_proxy<FreeSmartphone.UsageSync>( BusType.SYSTEM, FsoFramework.Usage.ServiceDBusName,
                FsoFramework.Usage.ServicePathPrefix );
        }
        catch ( GLib.Error err )
        {
            theLogger.error( @"Can't request proxy for usage subsystem; suspend handling will be not available!" );
        }
    }

    private async bool set_modem_power_state( SamsungIpc.Power.PhoneState state )
    {
        unowned SamsungIpc.Response? response = null;
        phone_pwr_state = state;

        // state is a 16 bit number we need to convert here into a uint8 array before we
        // can pass it to the queue
        var sb = new uint8[2];
        sb[0] = (state & 0x00ff);
        sb[1] = (state & 0xff00) >> 8;

        response = yield enqueue_async( SamsungIpc.RequestType.EXEC, SamsungIpc.MessageType.PWR_PHONE_STATE, sb );
        if ( response == null )
        {
            theLogger.error( @"Could not put modem into $(state) power state!" );
            return false;
        }

        return true;
    }

    //
    // public API
    //

    public IpcChannel( FsoGsm.Modem modem, string name, FsoFramework.Transport? transport )
    {
        base( transport );

        this.modem = modem;
        this.name = name;
        this.urchandler = new Samsung.UnsolicitedResponseHandler( this.modem );
        this.wakelock = new FsoFramework.Wakelock( "fsogsmd-modem-samsung" );
        Idle.add( () => { request_usage_service(); return false; } );

        modem.registerChannel( name, this );
        modem.signalStatusChanged.connect( onModemStatusChanged );

        fmtclient = new SamsungIpc.Client( SamsungIpc.ClientType.FMT );
        fmtclient.set_log_handler( ( message ) => { theLogger.debug( message ); } );
        fmtclient.set_io_handlers( modem_read_request, modem_write_request );
    }

    public override async bool open()
    {
        bool result = true;

        result = yield transport.openAsync();
        if (!result)
            return false;

        fmtclient.open();

        return true;
    }

    public override async void close()
    {
        fmtclient.close();
        transport.close();
    }

    /**
     * Send a new response to the modem and wait until we get the response back.
     *
     * @param type Type of the request (see {@link SamsungIpc.RequestType})
     * @param command Type of the command we're sending
     * @param data Data of the request
     * @param retries Number of times the request should resend when sending fails
     * @param timeout Time to wait until the request receives (zero means an unlimited timeout)
     * @return Response message received for the request or null if sending is not possible or a timeout occured
     **/
    public async unowned SamsungIpc.Response? enqueue_async( SamsungIpc.RequestType type, SamsungIpc.MessageType command, uint8[] data = new uint8[] { },
                                                             int retry = 0, int timeout = 5 )
    {
        if ( initialized && suspended )
        {
            theLogger.error( @"We can not send a request to the modem when we're suspended!" );
            return null;
        }

        assert( theLogger.debug( @"Enqueue a new command: type = $(type), command = $(command)" ) );

        var handler = new Samsung.CommandHandler();

        handler.client = fmtclient;
        handler.id = next_request_id();
        handler.callback = enqueue_async.callback;
        handler.retry = retry;
        handler.timeout = timeout;
        handler.message_type = command;
        handler.request_type = type;
        handler.data = data;

        suspend_lock++;
        enqueueCommand( handler );
        yield;
        suspend_lock--;

        // reset current command handler so we're able to send more commands again
        current = null;

        if ( handler.timed_out )
        {
            theLogger.error( @"Received a timeout while sending command $(command)!" );
            return null;
        }

        return handler.response;
    }

    public void registerUnsolicitedHandler( UnsolicitedHandler urchandler ) { }

    public void injectResponse( string response ) { assert_not_reached(); }

    public async bool suspend()
    {
        // we need to wait until all pending requests are finished otherwise we can't
        // acknowledge the suspend
        Timeout.add( 100, () => {
            assert( theLogger.debug( @"Checking wether we have pending requests to send to the modem ..." ) );
            if ( suspend_lock == 0 )
            {
                assert( theLogger.debug( @"We have no pending requests; suspending ..." ) );
                suspend.callback();
                return false;
            }
            assert( theLogger.debug( @"We have pending requests; can't suspend now!" ) );
            return true;
        } );
        yield;

        suspended = true;
        return true;
    }

    public async bool resume()
    {
        suspended = false;
        return true;
    }

    public async bool update_modem_power_state( SamsungIpc.Power.PhoneState state )
    {
        if ( state != phone_pwr_state )
            return yield set_modem_power_state( state );
        return true;
    }
}

// vim:ts=4:sw=4:expandtab
