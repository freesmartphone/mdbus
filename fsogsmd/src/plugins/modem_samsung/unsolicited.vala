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
                // Don't report signal strength when we are not registered
                if ( theModem.status() != FsoGsm.Modem.Status.ALIVE_REGISTERED )
                    break;

                ModemState.network_signal_strength = response.data[0];
                // notify the user about the change of signal strength
                var obj = theModem.theDevice<FreeSmartphone.GSM.Network>();
                obj.signal_strength( ModemState.network_signal_strength );
                break;

            case SamsungIpc.MessageType.GPRS_IP_CONFIGURATION:
                handle_gprs_ip_configuration( response );
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
                updateSimAuthStatus( FreeSmartphone.GSM.SIMAuthStatus.READY );
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

        ModemState.network_reg_state = (SamsungIpc.Network.RegistrationState) reginfo.reg_state;
        ModemState.network_act = (SamsungIpc.Network.AccessTechnology) reginfo.act;
        ModemState.network_lac = reginfo.lac;
        ModemState.network_cid = reginfo.cid;

        assert( logger.debug( @"domain = $(reginfo.domain), network_reg_state = $(ModemState.network_reg_state)" ) );
        assert( logger.debug( @"network_act = $(ModemState.network_act), lac = $(reginfo.lac), cid = $(reginfo.lac)" ) );
        assert( logger.debug( @"rej_cause = $(reginfo.rej_cause), edge = $(reginfo.edge)" ) );

        if ( theModem.status() >= FsoGsm.Modem.Status.ALIVE_SIM_READY )
            triggerUpdateNetworkStatus();
    }

    private void handle_gprs_ip_configuration( SamsungIpc.Response response )
    {
        var pdphandler = theModem.pdphandler as Samsung.PdpHandler;
        if (pdphandler == null)
            return;

        var ipresp = (SamsungIpc.Gprs.IpConfigurationMessage*) response.data;

        string local = ipAddrFromByteArray( ipresp.ip, 4 );
        string gateway = ipAddrFromByteArray( ipresp.gateway, 4 );
        string subnetmask = ipAddrFromByteArray( ipresp.subnet_mask, 4 );
        string dns1 = ipAddrFromByteArray( ipresp.dns1, 4 );
        string dns2 = ipAddrFromByteArray( ipresp.dns2, 4 );

        pdphandler.handleIpConfiguration( local, subnetmask, gateway, dns1, dns2 );
    }
}

// vim:ts=4:sw=4:expandtab
