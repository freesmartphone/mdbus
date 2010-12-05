/*
 * Copyright (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

public class MsmChannel : MsmCommandQueue, FsoGsm.Channel
{
    public FsoFramework.Transport transport { get; set; }
    public string name;

    public delegate void UnsolicitedHandler( string prefix, string response, string? pdu = null );

    private MsmUnsolicitedResponseHandler _urcHandler { get; set; }

    private Msmcomm.ModemControlStatus modemControlStatusOld { get; set; default = Msmcomm.ModemControlStatus.INACTIVE; }
    private bool restartRequested { get; set; default = false; }

    private MsmModemAgent _modemAgent;
    private bool _is_initialized;
    private bool _inHandleModemResetRequest = false;
    //
    // private API
    //

    /**
     * Handling the status updates from the low-lovel modem control layer
     **/
    private void onModemControlStatusUpdate(Msmcomm.ModemControlStatus status)
    {
        if ( _is_initialized && status == Msmcomm.ModemControlStatus.ACTIVE )
        {
            theModem.logger.debug("Msmcomm daemon is in ACTIVE state; synchronize with the modem ...");

            if (!_inHandleModemResetRequest)
            {
                handleModemResetRequest();
            }
        }

        modemControlStatusOld = status;
    }

    private async void handleModemResetRequest()
    {
        _inHandleModemResetRequest = true;
        if ( restartRequested )
        {
            theModem.logger.debug("A reset of the modem before synchronization is requested");
            yield resetModem();
            theModem.logger.debug("Modem is reseted, start synchronization with the modem");
            yield syncWithModem();
            restartRequested = false;
        }
        else
        {
            yield syncWithModem();
        }
        _inHandleModemResetRequest = false;
    }

    /**
     * Synchronize with the modem to have a common base for further commands (e.g. we can
     * recieve commands/responses from the modem)
     **/
    private async void syncWithModem()
    {
        try
        {
            yield _modemAgent.commands.test_alive();
            theModem.logger.debug("Synchronization is done; we should now recieve a lot of unsolicited responses");
        }
        catch ( DBus.Error err0 )
        {
        }
        catch ( Msmcomm.Error err1 )
        {
            theModem.logger.error("Can not synchronize with the modem; tried to synchronize without a reset before?");
        }
    }

    /**
     * Send the reset command to the modem
     **/
    private async void resetModem()
    {
        try
        {
            yield _modemAgent.commands.reset_modem();
            theModem.logger.debug("Reset command was send to the modem, now waiting for the modem to come back");
            yield _modemAgent.waitForUnsolicitedResponse( Msmcomm.UrcType.RESET_RADIO_IND );
            theModem.logger.debug("Modem is back, we can proceed with initialization");
        }
        catch ( DBus.Error err0 )
        {
        }
        catch ( Msmcomm.Error err1 )
        {
            theModem.logger.debug(@"Could not reset the modem; it responds with '$(err1.message)'");
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

    //
    // public API
    //

    public MsmChannel( string name )
    {
        base( new FsoFramework.NullTransport() );
        this.name = name;
        theModem.registerChannel( name, this );
        theModem.signalStatusChanged.connect( onModemStatusChanged );

        restartRequested = true;

        _modemAgent = MsmModemAgent.instance();
        _urcHandler = new MsmUnsolicitedResponseHandler( _modemAgent );
    }

    /**
     * Initialize all components we need to talk to the modem
     **/
    public async void initialize()
    {
        theModem.logger.debug("MSMCHANNEL: initialize ...");

        // Let the modem agent initialise itself
        _modemAgent.initialize();

        restartRequested = true;

        // Wait for modem agent to become ready
        // FIXME maybe there is some better way to do this?
        Timeout.add_seconds( 5, () => {
            if (_modemAgent.ready) {
                theModem.logger.debug("MsmModemAgent is now ready and we can proceed with initialization of the modem");
                open.callback();
                return false;
            }
            theModem.logger.debug("Modem agent is not ready yet ... waiting 5 seconds.");
            return true;
        });
        yield;

        // Connect to modem link layer status updates
        _modemAgent.management.status_update.connect(onModemControlStatusUpdate);

        // initialize modem and send reset command afterwards to come to a well
        // known state
        restartRequested = true;
        _modemAgent.management.initialize();

        // Setup up necessary handlers
        _urcHandler.setup();

        _is_initialized = true;

        theModem.logger.debug("MSMCHANNEL: modem initialization is finished!");
    }

    /**
     * Shutdown all components we don't need anymore
     **/
    public async void shutdown()
    {
        if ( _is_initialized )
        {
            _modemAgent.shutdown();
            _is_initialized = false;
        }
    }

    public void registerUnsolicitedHandler( UnsolicitedHandler urchandler )
    {
    }

    public void injectResponse( string response )
    {
        assert_not_reached();
    }

    public async bool suspend()
    {
        return true;
    }

    public async bool resume()
    {
        return true;
    }
}

