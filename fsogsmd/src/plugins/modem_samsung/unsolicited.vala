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

public void updateSimAuthStatus( FreeSmartphone.GSM.SIMAuthStatus status )
{
    theModem.logger.info( @"SIM Auth status now $status" );

    // send the dbus signal
    var obj = theModem.theDevice<FreeSmartphone.GSM.SIM>();
    obj.auth_status( status );

    // check whether we need to advance the modem state
    var data = theModem.data();
    if ( status != data.simAuthStatus )
    {
        data.simAuthStatus = status;

        // advance global modem state
        var modemStatus = theModem.status();
        if ( modemStatus == Modem.Status.INITIALIZING )
        {
            if ( status == FreeSmartphone.GSM.SIMAuthStatus.READY )
            {
                theModem.advanceToState( Modem.Status.ALIVE_SIM_UNLOCKED );
            }
            else
            {
                theModem.advanceToState( Modem.Status.ALIVE_SIM_LOCKED );
            }
        }
        else if ( modemStatus == Modem.Status.ALIVE_SIM_LOCKED )
        {
            if ( status == FreeSmartphone.GSM.SIMAuthStatus.READY )
            {
                theModem.advanceToState( Modem.Status.ALIVE_SIM_UNLOCKED );
            }
        }
        // NOTE: If we're registered to a network and we unregister then we need to
        // re-authenticate with the sim card and the correct pin. We are in REGISTERED or
        // UNLOCKED state before this, so we move to LOCKED sim state in this case.
        else if ( modemStatus == Modem.Status.ALIVE_REGISTERED || modemStatus == Modem.Status.ALIVE_SIM_UNLOCKED  )
        {
            if ( status == FreeSmartphone.GSM.SIMAuthStatus.PIN_REQUIRED )
            {
                theModem.advanceToState( Modem.Status.ALIVE_SIM_LOCKED, true );
            }
        }
    }
}


public class Samsung.UnsolicitedResponseHandler : FsoFramework.AbstractObject
{
    /**
     * Handling the various possible unsolicited responses we get from the modem
     **/
    public void process( SamsungIpc.Response response )
    {
        var channel = theModem.channel( "main" ) as Samsung.IpcChannel;

        switch ( response.command )
        {
            case SamsungIpc.MessageType.PWR_PHONE_PWR_UP:
                break;

            case SamsungIpc.MessageType.SEC_SIM_ICC_TYPE:
                ModemState.sim_icc_type = response.data[0];
                break;

            case SamsungIpc.MessageType.SEC_PIN_STATUS:
                handle_sim_status( response );
                break;

            case SamsungIpc.MessageType.NET_REGIST:
                handle_network_registration( response );
                break;

            case SamsungIpc.MessageType.PWR_PHONE_STATE:
                uint8 power_state = response.data[0];
                assert( logger.debug( @"phone state changed to state = 0x%02x".printf( power_state ) ) );
                handle_power_state( power_state );
                break;

            case SamsungIpc.MessageType.DISP_RSSI_INFO:
                ModemState.signal_strength = response.data[0];
                // notify the user about the change of signal strength
                var obj = theModem.theDevice<FreeSmartphone.GSM.Network>();
                obj.signal_strength( ModemState.signal_strength );
                break;
        }
    }

    public override string repr()
    {
        return @"<>";
    }

    //
    // private
    //

    private void handle_sim_status( SamsungIpc.Response response )
    {
        var message = (SamsungIpc.Security.SimStatusMessage*) response.data;

        if ( message.status == ModemState.sim_status )
            return;

        ModemState.sim_status = message.status;

        assert( logger.debug( @"sim status changed to status = 0x%02x".printf( ModemState.sim_status ) ) );

        switch ( message.status )
        {
            case SamsungIpc.Security.SimStatus.INIT_COMPLETE:
                theModem.advanceToState( FsoGsm.Modem.Status.ALIVE_SIM_READY );
                break;

            case SamsungIpc.Security.SimStatus.LOCK_SC:
                switch ( message.lock_status )
                {
                    case SamsungIpc.Security.SimLockStatus.PIN1_REQ:
                        updateSimAuthStatus( FreeSmartphone.GSM.SIMAuthStatus.PIN_REQUIRED );
                        break;
                    case SamsungIpc.Security.SimLockStatus.PUK_REQ:
                        updateSimAuthStatus( FreeSmartphone.GSM.SIMAuthStatus.PUK_REQUIRED );
                        break;
                    case SamsungIpc.Security.SimLockStatus.CARD_BLOCKED:
                        // FIXME we need a modem status for a blocked sim card!
                        theModem.advanceToState( FsoGsm.Modem.Status.ALIVE_NO_SIM );
                        break;
                }
                break;

            case SamsungIpc.Security.SimStatus.PB_INIT_COMPLETE:
                break;

            case SamsungIpc.Security.SimStatus.LOCK_FD:
            case SamsungIpc.Security.SimStatus.SIM_LOCK_REQUIRED:
            case SamsungIpc.Security.SimStatus.CARD_ERROR:
            case SamsungIpc.Security.SimStatus.CARD_NOT_PRESENT:
                theModem.advanceToState( FsoGsm.Modem.Status.ALIVE_NO_SIM );
                break;
        }
    }

    private void handle_power_state( uint8 power_state )
    {

        if ( power_state == ModemState.power_state )
            return;

        assert( logger.debug( @"phone state changed to state = 0x%02x".printf( power_state ) ) );
    }

    private void handle_network_registration( SamsungIpc.Response response )
    {
        SamsungIpc.Network.RegistrationMessage* reginfo = (SamsungIpc.Network.RegistrationMessage*) response.data;

        assert( logger.debug( @"Got updated network registration information from modem:" ) );
        assert( logger.debug( @" act = $(reginfo.act), domain = $(reginfo.domain)" ) );
        assert( logger.debug( @" status = $(reginfo.status), edge = $(reginfo.edge)" ) );
        assert( logger.debug( @" lac = $(reginfo.lac), cid = $(reginfo.lac), rej_cause = $(reginfo.rej_cause)" ) );
    }
}

