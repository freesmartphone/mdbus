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

using Gee;
using GLib;
using FsoGsm;

/**
 * MSM Unsolicited Base Class and Handler
 **/

public class MsmUnsolicitedResponseHandler
{
    private MsmModemAgent _modemAgent { get; set; }
    
    //
    // public API
    //
    
    public MsmUnsolicitedResponseHandler(MsmModemAgent agent)
    {
        this._modemAgent = agent;
    }
    
    public void setup()
    {
        _modemAgent.unsolicited.sim_not_available.connect(handleNoSimAvailable);
        _modemAgent.unsolicited.sim_removed.connect(handleSimRemoved);
        _modemAgent.unsolicited.pin1_verified.connect(handleSimPin1Verified);
        _modemAgent.unsolicited.pin1_enabled.connect(handleSimPin1Enabled);
        _modemAgent.unsolicited.pin1_disabled.connect(handleSimPin1Disabled);
        _modemAgent.unsolicited.pin1_blocked.connect(handleSimPin1Blocked);
        _modemAgent.unsolicited.pin1_unblocked.connect(handleSimPin1Unblocked);
        _modemAgent.unsolicited.pin2_verified.connect(handleSimPin2Verified);
        _modemAgent.unsolicited.pin2_enabled.connect(handleSimPin2Enabled);
        _modemAgent.unsolicited.pin2_disabled.connect(handleSimPin2Disabled);
        _modemAgent.unsolicited.pin2_blocked.connect(handleSimPin2Blocked);
        _modemAgent.unsolicited.pin2_unblocked.connect(handleSimPin2Unblocked);
        _modemAgent.unsolicited.network_state_info.connect(handleNetworkStateInfo);
        _modemAgent.unsolicited.reset_radio_ind.connect(handleResetRadioInd);
        _modemAgent.unsolicited.phonebook_modified.connect(handlePhonebookModified);
        _modemAgent.unsolicited.call_origination.connect(handleCallOrigination);
        _modemAgent.unsolicited.call_incomming.connect(handleCallIncomming);
        _modemAgent.unsolicited.call_connect.connect(handleCallConnect);
        _modemAgent.unsolicited.call_end.connect(handleCallEnd);
        _modemAgent.unsolicited.network_list.connect(handleNetworkList);
    }
    
    public virtual void handleResetRadioInd()
    {
        // the modem was reseted by ourself or somebody else. We should 
        // handle this and go into the initial state
        updateMsmSimAuthStatus( FreeSmartphone.GSM.SIMAuthStatus.PIN_REQUIRED );
    }

    //
    // SIM
    // 
    
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
        updateMsmSimAuthStatus( FreeSmartphone.GSM.SIMAuthStatus.PUK2_REQUIRED );
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
        var status = new GLib.HashTable<string,Value?>( str_hash, str_equal );

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
        
        _modemAgent.notifyUnsolicitedResponse( Msmcomm.UrcType.NETWORK_STATE_INFO, nsinfo.to_variant() );
    }
   
    public virtual void handleNetworkList( Msmcomm.NetworkProvider[] networks )
    {
    //    _modemAgent.notifyUnsolicitedResponse( Msmcomm.UrcType.NETWORK_LIST, networks.to_variant() );
    }

    //
    // Call
    //

    public virtual void handleCallOrigination( Msmcomm.CallInfo call_info )
    {
        _modemAgent.notifyUnsolicitedResponse( Msmcomm.UrcType.CALL_ORIGINATION, call_info.to_variant() );
    }
    
    public virtual void handleCallIncomming( Msmcomm.CallInfo call_info )
    {
        _modemAgent.notifyUnsolicitedResponse( Msmcomm.UrcType.CALL_INCOMMING, call_info.to_variant() );
        
        theModem.callhandler.handleIncomingCall( convertCallInfo( call_info) );
    }
    
    public virtual void handleCallConnect( Msmcomm.CallInfo call_info )
    {
        _modemAgent.notifyUnsolicitedResponse( Msmcomm.UrcType.CALL_CONNECT, call_info.to_variant() );
        
        theModem.callhandler.handleConnectingCall( convertCallInfo( call_info ) );
    }
    
    public virtual void handleCallEnd( Msmcomm.CallInfo call_info )
    {
        _modemAgent.notifyUnsolicitedResponse( Msmcomm.UrcType.CALL_END, call_info.to_variant() );
        
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
