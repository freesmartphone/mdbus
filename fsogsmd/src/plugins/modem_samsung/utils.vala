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
    var channel = theModem.channel( "main" ) as Samsung.IpcChannel;
    var functionality_level = "minimal";

    // Check if SIM access is possible, then we have basic functionality
    if ( theModem.status() == Modem.Status.ALIVE_SIM_READY &&
         channel.phone_pwr_state == SamsungIpc.Power.PhoneState.LPM )
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

private string ipAddrFromByteArray( uint8* data, int size )
{
    if ( size != 4 )
        return "0.0.0.0";
    return "%i.%i.%i.%i".printf( data[0], data[1], data[2], data[3] );
}

int convertRssiToSignalStrength( uint8 rssi )
{
    // NOTE the following is taken from samsung-ril which is found here:
    // git://gitorious.org/replicant/samsung-ril.git
    var r = rssi < 0x6f ? ((((rssi - 0x71) * -1) - ((rssi - 0x71) * -1) % 2) / 2) : 0;
    return Constants.instance().networkSignalToPercentage( r );
}

// vim:ts=4:sw=4:expandtab
