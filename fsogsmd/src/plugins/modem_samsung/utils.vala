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
using FsoFramework;

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

public string networkRegistrationStateToString( SamsungIpc.Network.RegistrationState reg_state )
{
    string result = "unknown";

    switch ( reg_state )
    {
        case SamsungIpc.Network.RegistrationState.HOME:
            result = "home";
            break;
        case SamsungIpc.Network.RegistrationState.SEARCHING:
            result = "busy";
            break;
        case SamsungIpc.Network.RegistrationState.EMERGENCY:
            result = "denied";
            break;
        case SamsungIpc.Network.RegistrationState.ROAMING:
            result = "roaming";
            break;
    }

    return result;
}

public string networkAccessTechnologyToString( SamsungIpc.Network.AccessTechnology act )
{
    string result = "unknown";

    switch ( act )
    {
        case SamsungIpc.Network.AccessTechnology.GSM:
        case SamsungIpc.Network.AccessTechnology.GSM2:
            result = "GSM";
            break;
        case SamsungIpc.Network.AccessTechnology.GPRS:
            result = "GPRS";
            break;
        case SamsungIpc.Network.AccessTechnology.EDGE:
            result = "EDGE";
            break;
        case SamsungIpc.Network.AccessTechnology.UMTS:
            result = "UMTS";
            break;
    }

    return result;
}

public void fillNetworkStatusInfo(GLib.HashTable<string,Variant> status)
{
    status.insert( "strength", @"$(Samsung.ModemState.network_signal_strength)" );

    status.insert( "provider", Samsung.ModemState.sim_provider_name );
    // status.insert( "network", MsmData.network_info.operator_name );
    status.insert( "display", Samsung.ModemState.sim_provider_name );

    if ( Samsung.ModemState.network_plmn != null && Samsung.ModemState.network_plmn.length > 0 )
        status.insert( "plmn", Samsung.ModemState.network_plmn );

    // status.insert( "mode", FIXME );

    status.insert( "registration", networkRegistrationStateToString( Samsung.ModemState.network_reg_state ) );
    status.insert( "mode", "automatic" );
    status.insert( "lac", @"$(Samsung.ModemState.network_lac)" );
    status.insert( "cid", @"$(Samsung.ModemState.network_cid)" );
    status.insert( "act", networkAccessTechnologyToString( Samsung.ModemState.network_act ) );

    if ( Samsung.ModemState.network_reg_state == SamsungIpc.Network.RegistrationState.HOME  ||
         Samsung.ModemState.network_reg_state == SamsungIpc.Network.RegistrationState.ROAMING )
    {
        // status.insert( "code", "%03u%02u".printf( MsmData.network_info.mcc, MsmData.network_info.mnc ) );
    }
}

/**
 * Update network status if something in network state has changed
 **/
public async void triggerUpdateNetworkStatus()
{
    unowned SamsungIpc.Response? response;

    if ( inTriggerUpdateNetworkStatus )
    {
        assert( theModem.logger.debug( "already gathering network status... ignoring additional trigger" ) );
        return;
    }

    inTriggerUpdateNetworkStatus = true;

    var channel = theModem.channel( "main" ) as Samsung.IpcChannel;

    // We requst the network registration state so we can decide on the on the last state
    // what we have to update and don't rely on a old state we saved a long time ago.
    response = yield channel.enqueue_async( SamsungIpc.RequestType.GET, SamsungIpc.MessageType.NET_REGIST, new uint8[] { 0xff, 0x02 } );
    if ( response == null )
    {
        assert( theLogger.error( @"Can't retrieve network registration state from modem!" ) );
    }
    else
    {
        var netresp = (SamsungIpc.Network.RegistrationMessage*) (response.data);
        Samsung.ModemState.network_reg_state = netresp.reg_state;
    }

    var mstat = theModem.status();

    // Advance modem status, if necessary
    if ( Samsung.ModemState.network_reg_state == SamsungIpc.Network.RegistrationState.HOME  ||
         Samsung.ModemState.network_reg_state == SamsungIpc.Network.RegistrationState.ROAMING )
    {
        if ( mstat != Modem.Status.ALIVE_REGISTERED )
        {
            theModem.advanceToState( Modem.Status.ALIVE_REGISTERED );
        }
    }
    else
    {
        // If we are not registered with a network but our status indicates a network
        // registration we should change the modem state
        if ( mstat == Modem.Status.ALIVE_REGISTERED )
        {
            theModem.advanceToState( Modem.Status.ALIVE_SIM_READY );
        }
    }

    // Send network status signal to connected clients
    var status = new GLib.HashTable<string,Variant>( str_hash, str_equal );
    fillNetworkStatusInfo( status );
    var network = theModem.theDevice<FreeSmartphone.GSM.Network>();
    network.status( status );

    inTriggerUpdateNetworkStatus = false;
}

// vim:ts=4:sw=4:expandtab
