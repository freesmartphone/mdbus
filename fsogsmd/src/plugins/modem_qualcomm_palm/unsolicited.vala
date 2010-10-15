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
        Msmcomm.RuntimeData.pin1_block_status = Msmcomm.SimPinStatus.PERM_BLOCKED;
    }
    
    public virtual void handleSimPin2PermBlocked()
    {
        Msmcomm.RuntimeData.pin2_block_status = Msmcomm.SimPinStatus.PERM_BLOCKED;
    }
    
    public virtual void handleSimPin1Blocked()
    {
        Msmcomm.RuntimeData.pin1_block_status = Msmcomm.SimPinStatus.BLOCKED;
    }
    
    public virtual void handleSimPin2Blocked()
    {
        Msmcomm.RuntimeData.pin2_block_status = Msmcomm.SimPinStatus.BLOCKED;
    }
    
    public virtual void handleSimPin1Unblocked()
    {
        Msmcomm.RuntimeData.pin1_block_status = Msmcomm.SimPinStatus.UNBLOCKED;
    }
    
    public virtual void handleSimPin2Unblocked()
    {
        Msmcomm.RuntimeData.pin2_block_status = Msmcomm.SimPinStatus.UNBLOCKED;
    }

    public virtual void handlePhonebookModified( Msmcomm.PhonebookBookType bookType, uint position )
    {
        // NOTE phonebook content has changed; we resync our phonebook here completly!
        // theModem.pbhandler.resync();
    }
        
    //
    // Network
    //

    public virtual void handleNetworkStateInfo(  Msmcomm.NetworkStateInfo nsinfo )
    {
        var status = new GLib.HashTable<string,Value?>( str_hash, str_equal );

        status.insert( "mode", "automatic" );
        status.insert( "strength", (int)nsinfo.rssi );
        status.insert( "registration", "home" );
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
    }
}
