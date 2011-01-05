/*
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *                         Simon Busch <morphis@gravedo.de>
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

using Gee;
using GLib;
using FsoGsm;

/**
 * MSM Unsolicited Base Class and Handler
 **/

public class MsmUnsolicitedResponseHandler
{
    //
    // public API
    //

    public void setup()
    {
        var channel = theModem.channel( "main" ) as MsmChannel;

        channel.unsolicited.sim_inserted.connect(handleSimAvailable);
        channel.unsolicited.sim_not_available.connect(handleNoSimAvailable);
        channel.unsolicited.sim_removed.connect(handleSimRemoved);
        channel.unsolicited.pin1_verified.connect(handleSimPin1Verified);
        channel.unsolicited.pin1_enabled.connect(handleSimPin1Enabled);
        channel.unsolicited.pin1_disabled.connect(handleSimPin1Disabled);
        channel.unsolicited.pin1_blocked.connect(handleSimPin1Blocked);
        channel.unsolicited.pin1_unblocked.connect(handleSimPin1Unblocked);
        channel.unsolicited.pin2_verified.connect(handleSimPin2Verified);
        channel.unsolicited.pin2_enabled.connect(handleSimPin2Enabled);
        channel.unsolicited.pin2_disabled.connect(handleSimPin2Disabled);
        channel.unsolicited.pin2_blocked.connect(handleSimPin2Blocked);
        channel.unsolicited.pin2_unblocked.connect(handleSimPin2Unblocked);
        channel.unsolicited.network_state_info.connect(handleNetworkStateInfo);
        channel.unsolicited.reset_radio_ind.connect(handleResetRadioInd);
        channel.unsolicited.phonebook_modified.connect(handlePhonebookModified);
        channel.unsolicited.call_origination.connect(handleCallOrigination);
        channel.unsolicited.call_incomming.connect(handleCallIncomming);
        channel.unsolicited.call_connect.connect(handleCallConnect);
        channel.unsolicited.call_end.connect(handleCallEnd);
        channel.unsolicited.network_list.connect(handleNetworkList);
        channel.unsolicited.operation_mode.connect(handleOperationMode);
    }


    public virtual void handleOperationMode()
    {
    }

    public virtual void handleResetRadioInd()
    {
        var channel = theModem.channel( "main" ) as MsmChannel;
        channel.notifyUnsolicitedResponse( Msmcomm.UrcType.RESET_RADIO_IND, null );
    }

    //
    // SIM
    //

    public virtual void handleSimAvailable()
    {
        updateMsmSimAuthStatus( FreeSmartphone.GSM.SIMAuthStatus.PIN_REQUIRED );
    }

    public virtual void handleNoSimAvailable()
    {
        theModem.advanceToState( Modem.Status.ALIVE_NO_SIM );
    }

    public virtual void handleSimRemoved()
    {
        // FIXME
    }

    public virtual void handleSimPin1Enabled()
    {
        // a SIM_PIN1_ENABLED does not mean that the PIN1 is required to come
        // into SIM_READY state, it means that you can use PIN1 to authenticate
        // with the SIM card - nothing more!
        // updateMsmSimAuthStatus( FreeSmartphone.GSM.SIMAuthStatus.PIN_REQUIRED );

        Msmcomm.RuntimeData.pin1_status = Msmcomm.SimPinStatus.ENABLED;
    }

    public virtual void handleSimPin2Enabled()
    {
        Msmcomm.RuntimeData.pin2_status = Msmcomm.SimPinStatus.ENABLED;
    }

    public virtual void handleSimPin1Verified()
    {
        updateMsmSimAuthStatus( FreeSmartphone.GSM.SIMAuthStatus.READY );
    }

    public virtual void handleSimPin2Verified()
    {
        updateMsmSimAuthStatus( FreeSmartphone.GSM.SIMAuthStatus.READY );
    }

    public virtual void handleSimPin1Disabled()
    {
        Msmcomm.RuntimeData.pin1_status = Msmcomm.SimPinStatus.DISABLED;
    }

    public virtual void handleSimPin2Disabled()
    {
        Msmcomm.RuntimeData.pin2_status = Msmcomm.SimPinStatus.DISABLED;
    }

    public virtual void handleSimPin1PermBlocked()
    {
        updateMsmSimAuthStatus( FreeSmartphone.GSM.SIMAuthStatus.UNKNOWN );
    }

    public virtual void handleSimPin2PermBlocked()
    {
        updateMsmSimAuthStatus( FreeSmartphone.GSM.SIMAuthStatus.UNKNOWN );
    }

    public virtual void handleSimPin1Blocked()
    {
        updateMsmSimAuthStatus( FreeSmartphone.GSM.SIMAuthStatus.PUK_REQUIRED );
    }

    public virtual void handleSimPin2Blocked()
    {
        // FIXME we ony should do this when PIN1 is even blocked!
        //  updateMsmSimAuthStatus( FreeSmartphone.GSM.SIMAuthStatus.PUK2_REQUIRED );
    }

    public virtual void handleSimPin1Unblocked()
    {
        updateMsmSimAuthStatus( FreeSmartphone.GSM.SIMAuthStatus.PIN_REQUIRED );
    }

    public virtual void handleSimPin2Unblocked()
    {
        updateMsmSimAuthStatus( FreeSmartphone.GSM.SIMAuthStatus.PIN2_REQUIRED );
    }

    public virtual void handlePhonebookModified( Msmcomm.PhonebookBookType bookType, uint position )
    {
        // NOTE phonebook content has changed; we resync our phonebook here completly!
        // theModem.pbhandler.syncWithSim();
    }

    //
    // Network
    //

    public virtual void handleNetworkStateInfo(  Msmcomm.NetworkStateInfo nsinfo )
    {
        var channel = theModem.channel( "main" ) as MsmChannel;
        var status = new GLib.HashTable<string,Variant>( str_hash, str_equal );

        status.insert( "mode", "automatic" );
        status.insert( "strength", (int)nsinfo.rssi );
        status.insert( "registration", Msmcomm.networkRegistrationStatusToString( nsinfo.registration_status ) );
        status.insert( "lac", "unknown" );
        status.insert( "cid", "unknown" );
        status.insert( "provider", nsinfo.operator_name );
        status.insert( "display", nsinfo.operator_name );
        status.insert( "code", "unknown" );
        status.insert( "pdp.registration", nsinfo.gprs_attached.to_string() );
        status.insert( "pdp.lac", "unknown" );
        status.insert( "pdp.cid", "unknown" );

        var obj = FsoGsm.theModem.theDevice<FreeSmartphone.GSM.Network>();
        obj.status( status );

        Msmcomm.RuntimeData.signal_strength = (int) nsinfo.rssi;
        Msmcomm.RuntimeData.current_operator_name = nsinfo.operator_name;
        Msmcomm.RuntimeData.network_reg_status = nsinfo.registration_status;
        Msmcomm.RuntimeData.networkServiceStatus = nsinfo.service_status;

        channel.notifyUnsolicitedResponse( Msmcomm.UrcType.NETWORK_STATE_INFO, nsinfo.to_variant() );
        
        triggerUpdateNetworkStatus();
    }

    public virtual void handleNetworkList( Msmcomm.NetworkProvider[] networks )
    {
    //    channel.notifyUnsolicitedResponse( Msmcomm.UrcType.NETWORK_LIST, networks.to_variant() );
    }

    //
    // Call
    //

    public virtual void handleCallOrigination( Msmcomm.CallInfo call_info )
    {
        var channel = theModem.channel( "main" ) as MsmChannel;
        channel.notifyUnsolicitedResponse( Msmcomm.UrcType.CALL_ORIGINATION, call_info.to_variant() );
    }

    public virtual void handleCallIncomming( Msmcomm.CallInfo call_info )
    {
        var channel = theModem.channel( "main" ) as MsmChannel;
        channel.notifyUnsolicitedResponse( Msmcomm.UrcType.CALL_INCOMMING, call_info.to_variant() );

        theModem.callhandler.handleIncomingCall( convertCallInfo( call_info) );
    }

    public virtual void handleCallConnect( Msmcomm.CallInfo call_info )
    {
        var channel = theModem.channel( "main" ) as MsmChannel;
        channel.notifyUnsolicitedResponse( Msmcomm.UrcType.CALL_CONNECT, call_info.to_variant() );

        theModem.callhandler.handleConnectingCall( convertCallInfo( call_info ) );
    }

    public virtual void handleCallEnd( Msmcomm.CallInfo call_info )
    {
        var channel = theModem.channel( "main" ) as MsmChannel;
        channel.notifyUnsolicitedResponse( Msmcomm.UrcType.CALL_END, call_info.to_variant() );

        theModem.callhandler.handleEndingCall( convertCallInfo( call_info ) );
    }

    //
    // private API
    //

    private FsoGsm.CallInfo convertCallInfo( Msmcomm.CallInfo call_info )
    {
        var result = new FsoGsm.CallInfo();
        result.ctype = "VOICE"; // FIXME we have DATA calls too!
        result.id = (int) call_info.id;
        return result;
    }
}

