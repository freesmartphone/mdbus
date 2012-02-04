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

public class Samsung.NetworkStatus : FsoFramework.AbstractObject
{
    private uint id = 0;
    private bool inTriggerUpdateNetworkStatus = false;

    public bool active { get; private set; default = false; }
    public int interval { get; set; default = 5; }

    //
    // private
    //

    private async void syncNetworkStatus()
    {
        try
        {
            // we're just executing the mediator here as the mediator will automatically send
            // the updated network status back to us.
            var m = theModem.createMediator<NetworkGetStatus>();
            yield m.run();
        }
        catch ( GLib.Error err )
        {
            logger.error( @"Something went wrong while receiving network status: $(err.message)" );
        }
    }

    private async void advanceNetworkStatus()
    {
        if ( inTriggerUpdateNetworkStatus )
        {
            assert( theModem.logger.debug( "already gathering network status... ignoring additional trigger" ) );
            return;
        }

        inTriggerUpdateNetworkStatus = true;

        assert( theLogger.debug( @"Start syncing network registration state with modem ..." ) );

        var mstat = theModem.status();

        // Advance modem status, if necessary
        if ( Samsung.ModemState.network_reg_state == SamsungIpc.Network.RegistrationState.HOME  ||
             Samsung.ModemState.network_reg_state == SamsungIpc.Network.RegistrationState.ROAMING )
        {
            if ( mstat != FsoGsm.Modem.Status.ALIVE_REGISTERED )
            {
                theModem.advanceToState( FsoGsm.Modem.Status.ALIVE_REGISTERED );
            }
        }
        else
        {
            // If we are not registered with a network but our status indicates a network
            // registration we should change the modem state
            if ( mstat == FsoGsm.Modem.Status.ALIVE_REGISTERED )
            {
                theModem.advanceToState( FsoGsm.Modem.Status.ALIVE_SIM_READY );
            }
        }

        assert( theLogger.debug( @"Finished syncing network registration state!" ) );

        inTriggerUpdateNetworkStatus = false;
    }

    //
    // public API
    //

    public void update( SamsungIpc.Response? response )
    {
        SamsungIpc.Network.RegistrationMessage* reginfo = (SamsungIpc.Network.RegistrationMessage*) response.data;

        if ( reginfo.domain == SamsungIpc.Network.ServiceDomain.GSM )
        {
            assert( logger.debug( @"Got updated network registration information from modem:" ) );

            ModemState.network_reg_state = (SamsungIpc.Network.RegistrationState) reginfo.reg_state;
            ModemState.network_act = (SamsungIpc.Network.AccessTechnology) reginfo.act;
            ModemState.network_lac = (int32) reginfo.lac;
            ModemState.network_cid = (int32) reginfo.cid;

            assert( logger.debug( @"domain = $(reginfo.domain), network_reg_state = $(ModemState.network_reg_state)" ) );
            assert( logger.debug( @"network_act = $(ModemState.network_act), lac = $(reginfo.lac), cid = $(reginfo.lac)" ) );
            assert( logger.debug( @"rej_cause = $(reginfo.rej_cause), edge = $(reginfo.edge)" ) );

            if ( theModem.status() >= FsoGsm.Modem.Status.ALIVE_SIM_READY )
            {
                advanceNetworkStatus();
            }
            else
            {
                assert( logger.debug( @"Didn't triggered a network status as we're not authenticated against the SIM card yet!" ) );
            }
        }
        else if ( reginfo.domain == SamsungIpc.Network.ServiceDomain.GPRS )
        {
            ModemState.pdp_reg_state = (SamsungIpc.Network.RegistrationState) reginfo.reg_state;
            ModemState.pdp_lac = (int32) reginfo.lac;
            ModemState.pdp_cid = (int32) reginfo.cid;
        }
        else
        {
            logger.warning( @"Got unknown network service domain type: 0x%02x".printf( reginfo.domain ) );
        }

        assert( theLogger.debug( @"Sending network status update signal to connected clients ..." ) );
        var status = new GLib.HashTable<string,Variant>( str_hash, str_equal );
        fillNetworkStatusInfo( status );
        var network = theModem.theDevice<FreeSmartphone.GSM.Network>();
        network.status( status );
    }

    public void start()
    {
        if ( active )
            return;

        assert( logger.debug( @"Start to poll network status ..." ) );
        id = Timeout.add_seconds( interval, () => {
            syncNetworkStatus();
            return true;
        } );

        active = true;
    }

    public void stop()
    {
        if ( !active )
            return;

        assert( logger.debug( @"Stop polling network status ..." ) );
        Source.remove( id );
    }

    public override string repr()
    {
        return @"<>";
    }
}

// vim:ts=4:sw=4:expandtab
