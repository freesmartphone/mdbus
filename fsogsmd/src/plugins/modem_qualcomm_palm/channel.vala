/*
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *                         Simon Busch <morphis@gravedo.de>
 *                         Lukas Märdian <lukasmaerdian@gmail.com>
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

public class MsmChannel : CommandQueue, Channel, AbstractObject
{
    private FreeSmartphone.Usage usage;
    private bool is_initialized;
    private Msmcomm.ModemStatus currentModemStatus;

    public Transport transport { get; set; }
    public string name;

    public MsmUnsolicitedResponseHandler urc_handler;
    public Msmcomm.Management management_service;
    public Msmcomm.State state_service;
    public Msmcomm.Misc misc_service;
    public Msmcomm.Call call_service;
    public Msmcomm.Sim sim_service;
    public Msmcomm.Phonebook phonebook_service;
    public Msmcomm.Network network_service;
    public Msmcomm.Sound sound_service;
    public Msmcomm.Sms sms_service;

    private async void onModemControlStatusChanged( Msmcomm.ModemStatus status )
    {
        currentModemStatus = status;

        /* ignore status updates as long as we are not initialized */
        if ( !is_initialized )
            return;

        switch ( status )
        {
            case Msmcomm.ModemStatus.ACTIVE:
                /* modem controller become active after it was successfully initialized?
                 * that can only one cause: modem was reseted due to internal error. We
                 * have to take care about this and re-synchronize with the modem.
                 */
                logger.error( "Modem control was reseted due to internal error; synchronizing with the modem ..." );

                // Manual sleep necessary before we can proceed to talk to the msmcommd
                Posix.sleep(2);
                misc_service.test_alive();

                break;
            case Msmcomm.ModemStatus.INACTIVE:
                break;
        }
    }

    private void onModemStatusChanged( FsoGsm.Modem modem, FsoGsm.Modem.Status status )
    {
        switch ( status )
        {
            case FsoGsm.Modem.Status.INITIALIZING:
                initialize();
                break;
            case FsoGsm.Modem.Status.CLOSING:
                shutdown();
                break;
            default:
                break;
        }
    }

    private async void onIncomingMessage( Msmcomm.SmsMessage message )
    {
        string hexpdu = "";
        int tpdulen = message.pdu.length;
        uint8 nr = message.nr;

        for ( int i = 0; i < tpdulen; i++ )
        {
            hexpdu += "%02x".printf (message.pdu[i]);
        }

        var sms_handler = new MsmSmsHandler();
        sms_handler.handleIncomingSms(hexpdu, tpdulen);

        var channel = theModem.channel( "main" ) as MsmChannel;
        try
        {  
            yield channel.sms_service.acknowledge_message( nr );
            logger.info( @"Acknowledged message nr: $(nr)" );
        }
        catch ( GLib.Error err0 )
        {  
            var msg0 = @"Could not process acknowledge_message, got: $(err0.message)";
            throw new FreeSmartphone.Error.INTERNAL_ERROR( msg0 );
        }
    }

    private async bool requestModemResource()
    {
        try
        {
            usage = Bus.get_proxy_sync<FreeSmartphone.Usage>( BusType.SYSTEM, "org.freesmartphone.ousaged", "/org/freesmartphone/Usage" );
            yield usage.request_resource( "Modem" );
        }
        catch ( GLib.Error err )
        {
            logger.error( @"Modem resource is not available: $(err.message)" );
            return false;
        }

        return true;
    }

    private bool registerObjects()
    {
        bool result = true;

        try
        {
            management_service = Bus.get_proxy_sync<Msmcomm.Management>( BusType.SYSTEM, "org.msmcomm", "/org/msmcomm" );
            management_service.modem_status.connect( onModemControlStatusChanged );
            misc_service =  Bus.get_proxy_sync<Msmcomm.Misc>( BusType.SYSTEM, "org.msmcomm", "/org/msmcomm" );
            sms_service = Bus.get_proxy_sync<Msmcomm.Sms>( BusType.SYSTEM, "org.msmcomm", "/org/msmcomm" );
            sms_service.incomming_message.connect( onIncomingMessage );
            state_service =  Bus.get_proxy_sync<Msmcomm.State>( BusType.SYSTEM, "org.msmcomm", "/org/msmcomm" );
            sim_service = Bus.get_proxy_sync<Msmcomm.Sim>( BusType.SYSTEM, "org.msmcomm", "/org/msmcomm" );
            phonebook_service = Bus.get_proxy_sync<Msmcomm.Phonebook>( BusType.SYSTEM, "org.msmcomm", "/org/msmcomm" );
            network_service = Bus.get_proxy_sync<Msmcomm.Network>( BusType.SYSTEM, "org.msmcomm", "/org/msmcomm" );
            call_service = Bus.get_proxy_sync<Msmcomm.Call>( BusType.SYSTEM, "org.msmcomm", "/org/msmcomm" );
            sound_service = Bus.get_proxy_sync<Msmcomm.Sound>( BusType.SYSTEM, "org.msmcomm", "/org/msmcomm" );
        }
        catch ( GLib.IOError err )
        {
            logger.error( @"Can't initialize msmcommd proxy objects: $(err.message)" );
            result = false;
        }

        return result;
    }

    private async void releaseModemResource()
    {
        try
        {
            logger.debug( "Releasing modem dbus resource ..." );
            yield usage.release_resource( "Modem" );
        }
        catch ( GLib.Error err )
        {
            logger.error( @"Could not release Modem resource!" );
        }
    }

    private async void initialize()
    {
        try
        {
            // set network as primary source for time updates
            var date_info = Msmcomm.DateInfo();
            date_info.time_source = Msmcomm.TimeSource.NETWORK;
            yield misc_service.set_date( date_info );

            // try to set charger mode always to usb and 1000mA (the mode will adjust the
            // current on it's own)
            var charger_info = Msmcomm.ChargerStatusInfo();
            charger_info.mode = Msmcomm.ChargerMode.USB;
            charger_info.voltage = Msmcomm.ChargerVoltage.VOLTAGE_1000mA;
            yield misc_service.set_charge( charger_info );
        }
        catch ( GLib.Error err0 )
        {
            logger.error( @"Could not initialize modem with initial settings: $(err0.message)" );
        }
    }

    private async void shutdown()
    {
        // NOTE do not any modem relevant things here as modem is already closed when we
        // get here!
    }

    /**
     * Little asynchronous helper method to let us wait until the modem becomes active.
     **/
    private async void waitUntilModemIsActive()
    {
        Timeout.add_seconds(1, () => {
            if ( currentModemStatus == Msmcomm.ModemStatus.ACTIVE )
            {
                waitUntilModemIsActive.callback();
                return false;
            }
            return true;
        });
        yield;
    }


    //
    // public API
    //

    public MsmChannel( string name )
    {
        urc_handler = new MsmUnsolicitedResponseHandler();

        is_initialized = false;
        currentModemStatus = Msmcomm.ModemStatus.UNKNOWN;

        this.name = name;
        theModem.registerChannel( name, this );
        theModem.signalStatusChanged.connect( onModemStatusChanged );

        FsoGsm.theServiceDependencies.append( "Modem" );
    }

    public bool is_ready()
    {
        return is_initialized;
    }

    public async bool open()
    {
        bool timeout = false;

        try
        {
            MsmData.reset();

            var result = yield requestModemResource();
            if ( !result )
                return false;

            if ( !registerObjects() )
                return false;

            /* initialize the modem controller itself */
            logger.debug( "Initialize modem controller ..." );
            yield management_service.initialize();

            /* wait as long as modem controller is not ready */
            logger.debug( "Waiting for modem controller to be fully initialized ..." );
            Timeout.add_seconds(2, () => {
                if ( currentModemStatus == Msmcomm.ModemStatus.ACTIVE )
                {
                    open.callback();
                    return false;
                }
                return true;
            });
            yield;

            urc_handler.setup();

            /* We sent here a test alive command to the modem to retrieve the response of
             * the change operation mode message after this. Never remove the delay! */
            yield misc_service.test_alive();
            Posix.sleep(2);

            /* reset the modem and wait for it to come back */
            logger.debug( "Reseting modem and waiting for it to come back ..." );
            yield state_service.change_operation_mode( Msmcomm.OperationMode.RESET );
            yield urc_handler.waitForUnsolicitedResponse( MsmUrcType.RESET_RADIO_IND );

            // Wait a little bit until the msmcomm daemon is ready to accept the next
            // command. If we do not add the manual sleep here we are too fast and will
            // never get an answer for any further command.
            Posix.sleep(2);

            logger.debug( "Modem is back after reset now; Synchronizing ..." );
            yield misc_service.test_alive();

            is_initialized = true;
        }
        catch ( GLib.Error err0 )
        {
            logger.error( @"Something failed while opening the channel: $(err0.message)" );
            close();
            return false;
        }

        return true;
    }

    public void injectResponse( string response )
    {
        assert_not_reached();
    }

    public async bool suspend()
    {
        bool result = true;

        try
        {
            // We need to tell the modem not to send any health or rssi reports during
            // suspend otherwise we will wakeup very quickly.
            yield network_service.report_health( false );
            yield network_service.report_rssi( false );

            // Add a little timeout to give msmcommd enough time to process everything
            Timeout.add_seconds(1, () => { suspend.callback(); return false; });
            yield;
        }
        catch ( GLib.Error error )
        {
            logger.error(@"Could not disable health and rssi reports: $(error.message)");
            result = false;
        }

        return result;
    }

    public async bool resume()
    {
        bool result = true;

        try
        {
            yield waitUntilModemIsActive();

            // Enable health and rssi report again after they were disabled before the
            // devices entered the suspend state.
            yield network_service.report_health( true );
            yield network_service.report_rssi( true );
        }
        catch ( GLib.Error error )
        {
            logger.error(@"Could not enable health and rssi reports: $(error.message)");
            result = false;
        }

        return result;
    }

    public async void close()
    {
        try
        {
            logger.debug( "Shutdown modem controller ..." );
            yield management_service.shutdown();
            yield releaseModemResource();
        }
        catch ( GLib.Error err0 )
        {
            // The called method above should not fail in most cases. When they returned
            // with an error it's often because the msmcomm daemon died and is not
            // available anymore.
        }

        is_initialized = false;
    }

    public void registerUnsolicitedHandler( FsoFramework.CommandQueue.UnsolicitedHandler urchandler )
    {
    }

    public async void freeze( bool drain = false )
    {
    }

    public async void thaw()
    {
    }

    public override string repr()
    {
        return "<>";
    }
}

// vim:ts=4:sw=4:expandtab
