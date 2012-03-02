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
        var callhandler = theModem.callhandler as Samsung.CallHandler;

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
                triggerUpdateNetworkStatus();
                break;

            case SamsungIpc.MessageType.PWR_PHONE_STATE:
                uint8 power_state = response.data[0];
                handle_power_state( power_state );
                break;

            case SamsungIpc.MessageType.DISP_RSSI_INFO:
                // Don't report signal strength when we are not registered
                if ( theModem.status() != FsoGsm.Modem.Status.ALIVE_REGISTERED )
                    break;
                handle_signal_strength( response.data[0] );
                break;

            case SamsungIpc.MessageType.GPRS_IP_CONFIGURATION:
                handle_gprs_ip_configuration( response );
                break;

            case SamsungIpc.MessageType.CALL_INCOMING:
            case SamsungIpc.MessageType.CALL_RELEASE:
            case SamsungIpc.MessageType.CALL_STATUS:
            case SamsungIpc.MessageType.CALL_OUTGOING:
                callhandler.syncCallStatusAsync();
                break;

            case SamsungIpc.MessageType.SMS_DEVICE_READY:
                Idle.add( () => { handle_sms_device_ready(); return false; } );
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

    private void handle_signal_strength( uint8 rssi )
    {
        var strength = convertRssiToSignalStrength( rssi );

        // notify the user about the change of signal strength
        var obj = theModem.theDevice<FreeSmartphone.GSM.Network>();
        obj.signal_strength( strength );
    }

    private void handle_sim_status( SamsungIpc.Response response )
    {
        var message = (SamsungIpc.Security.SimStatusMessage*) response.data;

        if ( message.status == ModemState.sim_status )
            return;

        ModemState.sim_status = message.status;

        assert( logger.debug( @"sim status changed to status = 0x%02x".printf( message.status ) ) );

        switch ( (uint8) message.status )
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

    private async void handle_sms_device_ready()
    {
        var channel = theModem.channel( "main" ) as Samsung.IpcChannel;
        unowned SamsungIpc.Response? response;

        // When we get the SMS_DEVICE_READY urc we're already ready for processing
        // incoming SMS message
        response = yield channel.enqueue_async( SamsungIpc.RequestType.SET, SamsungIpc.MessageType.SMS_DEVICE_READY );
    }
}

// vim:ts=4:sw=4:expandtab
