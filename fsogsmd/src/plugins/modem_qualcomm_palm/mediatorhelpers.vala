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
using FsoGsm;

/**
 * Public helpers
 **/

public void fillNetworkStatusInfo(GLib.HashTable<string,Variant> status)
{
    status.insert( "strength", convertRawRssiToPercentage( MsmData.network_info.rssi ) );
    status.insert( "provider", MsmData.network_info.operator_name );
    status.insert( "network", MsmData.network_info.operator_name );
    status.insert( "display", MsmData.network_info.operator_name );
    status.insert( "registration", networkRegistrationStatusToString( MsmData.network_info.reg_status ) );
    status.insert( "mode", "automatic" );
    status.insert( "lac", "unknown" );
    status.insert( "cid", "unknown" );
    status.insert( "act", networkDataServiceToActString( MsmData.network_info.data_service ) );

    if ( MsmData.network_info.reg_status == Msmcomm.NetworkRegistrationStatus.HOME ||
         MsmData.network_info.reg_status == Msmcomm.NetworkRegistrationStatus.ROAMING )
    {
        status.insert( "code", "%u%u".printf( MsmData.network_info.mcc,
                                              MsmData.network_info.mnc ) );
    }
}

public void updateMsmSimAuthStatus( FreeSmartphone.GSM.SIMAuthStatus status )
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

/**
 * Modem facilities helpers
 **/
public async void gatherSimOperators() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
{
    /*
    var data = theModem.data();
    if ( data.simOperatorbook == null );
    {
        var copn = theModem.createAtCommand<PlusCOPN>( "+COPN" );
        var response = yield theModem.processAtCommandAsync( copn, copn.execute() );
        if ( copn.validateMulti( response ) == Constants.AtResponse.VALID )
        {
            data.simOperatorbook = copn.operators;
        }
        else
        {
            data.simOperatorbook = new GLib.HashTable<string,string>( GLib.str_hash, GLib.str_equal );
        }
    }
    */
}

static bool inGatherSimStatusAndUpdate;
static bool inTriggerUpdateNetworkStatus;

public async void gatherSimStatusAndUpdate() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
{
    if ( inGatherSimStatusAndUpdate )
    {
        assert( theModem.logger.debug( "already gathering sim status... ignoring additional trigger" ) );
        return;
    }
    inGatherSimStatusAndUpdate = true;

    var data = theModem.data();

    theModem.logger.info( @"SIM Auth status $(MsmData.sim_auth_status)" );
    var obj = theModem.theDevice<FreeSmartphone.GSM.SIM>();
    obj.auth_status( MsmData.sim_auth_status );

    // check wether we need to advance the modem state 
    if ( data.simAuthStatus != MsmData.sim_auth_status )
    {
        data.simAuthStatus = MsmData.sim_auth_status;

        // advance global modem state
        var modemStatus = theModem.status();
        if ( modemStatus >= Modem.Status.INITIALIZING && modemStatus <= Modem.Status.ALIVE_REGISTERED )
        {
            if ( MsmData.sim_auth_status == FreeSmartphone.GSM.SIMAuthStatus.READY )
            {
                theModem.advanceToState( Modem.Status.ALIVE_SIM_UNLOCKED, true );
            }
            else
            {
                theModem.advanceToState( Modem.Status.ALIVE_SIM_LOCKED, true );
            }
        }
    }

    inGatherSimStatusAndUpdate = false;
}

/**
 * Update network status if something in network state has changed
 **/
public async void triggerUpdateNetworkStatus()
{
    if ( inTriggerUpdateNetworkStatus )
    {
        assert( theModem.logger.debug( "already gathering network status... ignoring additional trigger" ) );
        return;
    }
    inTriggerUpdateNetworkStatus = true;

    var mstat = theModem.status();

    // Ignore, if we don't have proper status to issue networking commands yet
    if ( mstat != Modem.Status.ALIVE_SIM_READY && mstat != Modem.Status.ALIVE_REGISTERED )
    {
        assert( theModem.logger.debug( @"triggerUpdateNetworkStatus() ignored while modem is in status $mstat" ) );
        inTriggerUpdateNetworkStatus = false;
        return;
    }


    // Advance modem status, if necessary
    if ( MsmData.network_info.reg_status == Msmcomm.NetworkRegistrationStatus.HOME  ||
         MsmData.network_info.reg_status == Msmcomm.NetworkRegistrationStatus.ROAMING )
    {
        if ( mstat != Modem.Status.ALIVE_REGISTERED )
        {
            theModem.advanceToState( Modem.Status.ALIVE_REGISTERED );
        }
    }

    // Send network status signal to connected clients
    var status = new GLib.HashTable<string,Variant>( str_hash, str_equal );
    fillNetworkStatusInfo( status );
    var network = theModem.theDevice<FreeSmartphone.GSM.Network>();
    network.status( status );
    network.signal_strength( convertRawRssiToPercentage(MsmData.network_info.rssi) );

    inTriggerUpdateNetworkStatus = false;
}
