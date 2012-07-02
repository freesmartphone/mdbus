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
using Gee;
using FsoGsm;
using GIsiComm;

/**
 * @class IsiCallHandler
 **/
public class FsoGsm.IsiCallHandler : FsoGsm.CallHandler, FsoFramework.AbstractObject
{
    protected HashMap<int, FsoGsm.Call> calls;

    public IsiCallHandler()
    {
        calls = new HashMap<int, FsoGsm.Call>();
    }

    public override string repr()
    {
        return "<>";
    }

    public void handleStatusUpdate( GIsiComm.Call.ISI_CallStatus istatus )
    {
        FsoGsm.Call call;

        if ( calls.has_key( istatus.id ) )
        {
            assert( logger.debug( @"existing call with id $(istatus.id)" ) );
            call = calls[istatus.id];
        }
        else
        {
            assert( logger.debug( @"new call with id $(istatus.id)" ) );
            call = new FsoGsm.Call.newFromId( istatus.id );
            calls.set( istatus.id, call );
        }

        switch ( istatus.status )
        {
            case GIsiClient.Call.Status.COMING:
                assert( logger.debug( @"incoming call with id $(istatus.id) from $(istatus.number)" ) );
                call.detail.properties.insert( "direction", "incoming" );
                call.detail.properties.insert( "peer", Constants.phonenumberTupleToString( istatus.number, istatus.ntype ) );
                call.update_status( FreeSmartphone.GSM.CallStatus.INCOMING );
                break;

            case GIsiClient.Call.Status.CREATE:
                assert( logger.debug( @"outgoing call with id $(istatus.id) to $(istatus.number)" ) );
                call.detail.properties.insert( "direction", "outgoing" );
                call.detail.properties.insert( "peer", Constants.phonenumberTupleToString( istatus.number, istatus.ntype ) );
                call.update_status( FreeSmartphone.GSM.CallStatus.OUTGOING );
                break;

            case GIsiClient.Call.Status.ACTIVE:
                assert( logger.debug( @"call with id $(istatus.id) is active now" ) );
                call.update_status( FreeSmartphone.GSM.CallStatus.ACTIVE );
                break;

            case GIsiClient.Call.Status.HOLD:
                assert( logger.debug( @"call with id $(istatus.id) is on hold now" ) );
                call.update_status( FreeSmartphone.GSM.CallStatus.HELD );
                break;

            case GIsiClient.Call.Status.IDLE:
                assert( logger.debug( @"call with id $(istatus.id) is released" ) );
                call.update_status( FreeSmartphone.GSM.CallStatus.RELEASE );
                break;

            default:
                assert( logger.debug( @"ignoring callstatus $(istatus.status) for call with id $(istatus.id)" ) );
                break;
        }
    }

    public void handleIncomingCall( FsoGsm.CallInfo call_info )
    {
    }

    public void handleConnectingCall( FsoGsm.CallInfo call_info )
    {
    }

    public void handleEndingCall( FsoGsm.CallInfo call_info )
    {
    }

    public void addSupplementaryInformation( string direction, string info )
    {
    }

    //
    // User Actions (forwarded through the generic mediators)
    //
    public async void activate( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        NokiaIsi.isimodem.call.answerVoiceCall( (uint8) id, (error) => {
            if ( error == ErrorCode.OK )
            {
                activate.callback();
            }
            else
            {
                throw new FreeSmartphone.GSM.Error.DEVICE_FAILED( "Unknown ISI Error" );
            }
        } );
        yield;
    }

    public async int initiate( string number, string ctype ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        if ( ctype != "voice" )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "This modem only supports voice calls" );
        }

        uint8 ntype;
        var gsmnumber = Constants.phonenumberStringToRealTuple( number, out ntype );

        NokiaIsi.isimodem.call.initiateVoiceCall( gsmnumber, ntype, GIsiClient.Call.PresentationType.GSM_DEFAULT, (error, id) => {
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

    public async void hold() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async void release( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        if ( !calls.has_key( id ) )
        {
            throw new FreeSmartphone.GSM.Error.CALL_NOT_FOUND( "Call with specified id is not available" );
        }

        if ( calls[id].detail.status == FreeSmartphone.GSM.CallStatus.RELEASE )
        {
            throw new FreeSmartphone.GSM.Error.CALL_NOT_FOUND( "No active call with that id found" );
        }

        NokiaIsi.isimodem.call.releaseVoiceCall( (uint8) id, GIsiClient.Call.CauseType.CLIENT, GIsiClient.Call.IsiCause.RELEASE_BY_USER, (error) => {
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

    public async void releaseAll() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        foreach ( var call in calls.values )
        {
            if ( call.detail.status != FreeSmartphone.GSM.CallStatus.RELEASE )
            {
                try
                {
                    release( call.detail.id );
                }
                catch ( Error err )
                {
                }
            }
        }
    }

    public async FreeSmartphone.GSM.CallDetail[] listCalls() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var ret = new FreeSmartphone.GSM.CallDetail[] {};

        foreach ( var call in calls.values )
        {
            if ( call.detail.status != FreeSmartphone.GSM.CallStatus.RELEASE )
            {
                ret += call.detail;
            }
        }

        return ret;
    }

    public async void transfer() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }

    public async void deflect( string number ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }

    public override async void conference( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }

    public override async void join() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }
}

// vim:ts=4:sw=4:expandtab
