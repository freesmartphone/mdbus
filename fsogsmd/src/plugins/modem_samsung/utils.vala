/*
 * Copyright (C) 2010-2011 Simon Busch <morphis@gravedo.de>
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

using FsoGsm;

static bool inTriggerUpdateNetworkStatus;

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



/**
 * Determine functionality level according to modem state
 **/
public static string gatherFunctionalityLevel()
{
    var functionality_level = "minimal";

    // Check if SIM access is possible, then we have basic functionality
    if ( theModem.status() == Modem.Status.ALIVE_SIM_READY )
    {
        functionality_level = "airplane";
    }
    else if ( theModem.status() == Modem.Status.ALIVE_REGISTERED )
    {
        functionality_level = "full";
    }

    return functionality_level;
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

#if 0
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
#endif

    inTriggerUpdateNetworkStatus = false;
}

// vim:ts=4:sw=4:expandtab
