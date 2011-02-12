/*
 * Copyright (C) 2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
using GIsiComm;

/**
 * @class IsiCallHandler
 **/
public class FsoGsm.IsiCallHandler : FsoGsm.AbstractCallHandler
{
    public override string repr()
    {
        return "<>";
    }

    public override void handleIncomingCall( FsoGsm.CallInfo call_info )
    {
    }

    public override void handleConnectingCall( FsoGsm.CallInfo call_info )
    {
    }

    public override void handleEndingCall( FsoGsm.CallInfo call_info )
    {
    }

    public override void addSupplementaryInformation( string direction, string info )
    {
    }

    protected override async void cancelOutgoingWithId( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }

    protected override async void rejectIncomingWithId( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }

    protected override void startTimeoutIfNecessary()
    {
    }

    //
    // User Actions (forwarded through the generic mediators)
    //
    public override async void activate( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public override async int initiate( string number, string ctype ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        if ( ctype != "voice" )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "This modem only supports voice calls" );
        }

        NokiaIsi.isimodem.call.initiateVoiceCall( number, 145, GIsiClient.Call.PresentationType.GSM_DEFAULT, (error) => {
            if ( error == ErrorCode.OK )
            {
                initiate.callback();
            }
            else
            {
                throw new FreeSmartphone.GSM.Error.DEVICE_FAILED( "Unknown ISI Error" );
            }
        } );
        yield;

        return 0;
    }

    public override async void hold() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public override async void release( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        NokiaIsi.isimodem.call.releaseVoiceCall( (uint8) id-1, GIsiClient.Call.CauseType.CLIENT, GIsiClient.Call.IsiCause.RELEASE_BY_USER, (error) => {
            if ( error == ErrorCode.OK )
            {
                release.callback();
            }
            else
            {
                throw new FreeSmartphone.GSM.Error.DEVICE_FAILED( "Unknown ISI Error" );
            }
        } );
        yield;
    }

    public override async void releaseAll() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }
}
