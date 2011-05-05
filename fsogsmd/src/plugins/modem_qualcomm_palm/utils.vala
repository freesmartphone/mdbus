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

public static void handleMsmcommErrorMessage( Msmcomm.Error error ) throws FreeSmartphone.Error
{
    var msg = @"Could not process command, got: $(error.message)";
    throw new FreeSmartphone.Error.INTERNAL_ERROR( msg );
}

public static string gatherFunctionalityLevel()
{
    var functionality_level = "minimal";

    // Check if SIM access is possible, then we have basic functionality
    if ( theModem.status() == Modem.Status.ALIVE_SIM_READY ||
            theModem.status() == Modem.Status.ALIVE_REGISTERED )
    {
        functionality_level = "airplane";

        // If we are now registered with the network we have reached full 
        // functionality level
        if (theModem.status() == Modem.Status.ALIVE_REGISTERED &&
            MsmData.operation_mode == Msmcomm.OperationMode.ONLINE)
        {
            functionality_level = "full";
        }
    }

    return functionality_level;
}

public static string networkDataServiceToActString( Msmcomm.NetworkDataService data_service )
{
    string result = "GSM";

    switch ( data_service )
    {
        case Msmcomm.NetworkDataService.EDGE:
            result = "EDGE";
            break;
        case Msmcomm.NetworkDataService.HSDPA:
            result = "HSDPA";
            break;
    }

    return result;
}

public static FsoGsm.CallInfo createCallInfo( Msmcomm.CallStatusInfo info )
{
    var result = new FsoGsm.CallInfo();

    result.id = (int) info.id;

    switch ( info.type )
    {
        case Msmcomm.CallType.DATA:
            result.ctype = "data";
            break;
        case Msmcomm.CallType.AUDIO:
            result.ctype = "voice";
            break;
    }

    result.cinfo.insert( "number", info.number );

    return result;
}

public int convertRawRssiToPercentage( uint raw_rssi )
{
    int result = 0;

    // NOTE this conversation is based on meassured values from logs of the
    // TelephonyInterfaceLayer daemon from webOS. We don't know the exact formular to
    // convert raw rssi values to percentage values. The appropiate function looks like
    // f(x) = a + b * sqrt(-x + c). Need to find out the correct constants for a, b and c
    // and create a little LUT to speed up calculation.

    if ( raw_rssi < 72 )
    {
        result = 100;
    }
    else if ( raw_rssi < 86 )
    {
        result = 80;
    }
    else if ( raw_rssi < 100 )
    {
        result = 60;
    }
    else if ( raw_rssi < 107 )
    {
        result = 40;
    }
    else if ( raw_rssi < 117 )
    {
        result = 20;
    }

    return result;
}

// vim:ts=4:sw=4:expandtab
