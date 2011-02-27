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

using Gee;
using FsoGsm;

internal const int CALL_STATUS_REFRESH_TIMEOUT = 3; // in seconds

/**
 * @class FsoGsm.GenericAtCallHandler
 */

public class MsmCallHandler : FsoGsm.AbstractCallHandler
{
    protected HashMap<int, FsoGsm.Call> calls;
    protected FsoFramework.Pair<string,string> supplementary;

    //
    // public API
    //

    public MsmCallHandler()
    {
        calls = new HashMap<int, FsoGsm.Call>();
    }

    public override string repr()
    {
        return "<>";
    }

    public override void addSupplementaryInformation( string direction, string info )
    {
        supplementary = new FsoFramework.Pair<string,string>( direction, info );
    }

    //
    // DBus methods, delegated from the Call mediators
    //
    public override async void activate( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var channel = theModem.channel( "main" ) as MsmChannel;

        try
        {
            if ( id < 1 || id > Constants.CALL_INDEX_MAX )
            {
                throw new FreeSmartphone.Error.INVALID_PARAMETER( "Call index needs to be within [ 1, %d ]".printf( (int)Constants.CALL_INDEX_MAX) );
            }

            if ( !calls.has_key( id ) )
            {
                throw new FreeSmartphone.Error.INVALID_PARAMETER( "Call with specified id is not available" );
            }

            if ( calls[id].detail.status != FreeSmartphone.GSM.CallStatus.INCOMING && 
                 calls[id].detail.status != FreeSmartphone.GSM.CallStatus.HELD )
            {
                throw new FreeSmartphone.GSM.Error.CALL_NOT_FOUND( "No suitable call to activate found" );
            }

            if ( numberOfBusyCalls() == 0 ) // simple case
            {
                yield channel.call_service.answer_call( id );
            }
            else
            {
                // We already have an active call so hold it accept the new incomming call
                yield channel.call_service.sups_call( Msmcomm.SupsAction.HOLD_ALL_AND_ACCEPT_WAITING_OR_HELD, 0 );
            }
        }
        catch ( Msmcomm.Error err0 )
        {
            handleMsmcommErrorMessage( err0 );
        }
        catch ( Error err1 )
        {
        }
    }

    /**
     * Initiate a call with a specified number; can be a voice or data call
     **/
    public override async int initiate( string number, string ctype ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        int num = 0;
        var channel = theModem.channel( "main" ) as MsmChannel;

        if ( numberOfBusyCalls() > 0 )
        {
            throw new FreeSmartphone.GSM.Error.CALL_NOT_FOUND( "System busy" );
        }

        try 
        {
            // Initiate call to the selected number
            yield channel.call_service.originate_call(number, false);

            // Wait until the modem reports the origination of our new call
            var call_info = ( yield channel.urc_handler.waitForUnsolicitedResponse( MsmUrcType.CALL_ORIGINATION ) ) as Msmcomm.CallStatusInfo;

            // ... and store the new call in our internal list
            var call = new FsoGsm.Call.newFromId( (int) call_info.id );
            calls.set( (int) call_info.id, call );
        }
        catch ( Msmcomm.Error err0 )
        {
            handleMsmcommErrorMessage( err0 );
        }
        catch ( Error err1 )
        {
        }

        return num;
    }

    /**
     * Hold all already active call
     **/
    public override async void hold() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var channel = theModem.channel( "main" ) as MsmChannel;

        try 
        {
            if ( numberOfCallsWithStatus( FreeSmartphone.GSM.CallStatus.ACTIVE ) == 0 )
            {
                throw new FreeSmartphone.GSM.Error.CALL_NOT_FOUND( "No active call present" );
            }
            if ( numberOfCallsWithStatus( FreeSmartphone.GSM.CallStatus.INCOMING ) > 0 )
            {
                throw new FreeSmartphone.GSM.Error.CALL_NOT_FOUND( "Call incoming. Can't hold active calls without activating" );
            }
 
            yield channel.call_service.sups_call( 0, Msmcomm.SupsAction.HOLD_ALL_AND_ACCEPT_WAITING_OR_HELD );
        }
        catch ( Msmcomm.Error err0 )
        {
            handleMsmcommErrorMessage( err0 );
        }
        catch ( Error err1 )
        {
        }
    }

    /**
     * Release an already active call
     **/
    public override async void release( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var channel = theModem.channel( "main" ) as MsmChannel;

        try
        {
            if ( id < 1 || id > Constants.CALL_INDEX_MAX )
            {
                throw new FreeSmartphone.Error.INVALID_PARAMETER( "Call index needs to be within [ 1, %d ]".printf( (int)Constants.CALL_INDEX_MAX) );
            }

            if ( !calls.has_key( id ) )
            {
                throw new FreeSmartphone.Error.INVALID_PARAMETER( "Call with specified id is not available" );
            }

            if ( calls[id].detail.status == FreeSmartphone.GSM.CallStatus.RELEASE )
            {
                throw new FreeSmartphone.GSM.Error.CALL_NOT_FOUND( "No suitable call to release found" );
            }
            if ( calls[id].detail.status == FreeSmartphone.GSM.CallStatus.OUTGOING )
            {
                yield cancelOutgoingWithId( id );
                return;
            }

            if ( numberOfCallsWithStatus( FreeSmartphone.GSM.CallStatus.INCOMING ) == 1 && 
                 calls[id].detail.status == FreeSmartphone.GSM.CallStatus.INCOMING )
            {
                yield rejectIncomingWithId( id );
                return;
            }
            else
            {
                yield channel.call_service.sups_call( id, Msmcomm.SupsAction.DROP_SPECIFIC_AND_ACCEPT_WAITING_OR_HELD );
            }
        }
        catch ( Msmcomm.Error err0 )
        {
            handleMsmcommErrorMessage( err0 );
        }
        catch ( Error err1 )
        {
        }
    }

    /**
     * Release all calls
     **/
    public override async void releaseAll() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }

    /**
     * Handle an incomming call 
     **/
    public override void handleIncomingCall( FsoGsm.CallInfo call_info )
    {
        var new_call = new FsoGsm.Call.newFromId( call_info.id );

        var empty_properties = new GLib.HashTable<string,GLib.Variant>( str_hash, str_equal );
        var call_detail = FreeSmartphone.GSM.CallDetail( call_info.id, 
                                                         FreeSmartphone.GSM.CallStatus.INCOMING,
                                                         empty_properties );
        new_call.update( call_detail );

        calls.set( call_info.id, new_call );
    }

    /**
     * Handle an connecting call
     **/
    public override void handleConnectingCall( FsoGsm.CallInfo call_info )
    {
        if ( !calls.has_key( call_info.id ) )
        {
            var call = calls[ call_info.id ];
            call.update_status( FreeSmartphone.GSM.CallStatus.OUTGOING );
        }
        else
        {
            logger.warning( "callhandler got connecting call which is not known as incomming before!" );
        }
    }

    /**
     * Handle an ending call
     **/
    public override void handleEndingCall( FsoGsm.CallInfo call_info )
    {
        if ( calls.has_key( call_info.id ) )
        {
            var call = calls.get( call_info.id );
            call.update_status( FreeSmartphone.GSM.CallStatus.RELEASE );
            calls.unset( call_info.id );
        }
        else
        {
            logger.warning( "callhandler got ending call which is not known as active before!" );
        }
    }

    //
    // protected API
    //

    protected override void startTimeoutIfNecessary()
    {
    }

    protected override async void cancelOutgoingWithId( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        assert( logger.debug( @"Cancelling outgoing call with ID $id" ) );

        try
        {
            var channel = theModem.channel( "main" ) as MsmChannel;
            yield channel.call_service.end_call( id );
        }
        catch ( Msmcomm.Error err0 )
        {
            handleMsmcommErrorMessage( err0 );
        }
        catch ( Error err1 )
        {
        }
    }

    protected override async void rejectIncomingWithId( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        assert( logger.debug( @"Rejecting incoming call with ID $id" ) );

        var channel = theModem.channel( "main" ) as MsmChannel;

        try
        {
            // NOTE currently we reject an incomming call by dropping all calls or send a busy
            // signal when we have no active calls. Maybe there is another way in msmcomm
            // to do reject an incomming call but we currently don't know about.
            var cmd_type = Msmcomm.SupsAction.DROP_ALL_OR_SEND_BUSY;
            yield channel.call_service.sups_call( 0, cmd_type );
        }
        catch ( Msmcomm.Error err0 )
        {
            handleMsmcommErrorMessage( err0 );
        }
        catch ( Error err1 )
        {
        }
    }

    // 
    // private API
    //

    private int numberOfBusyCalls()
    {
        var num = 0;

        foreach (var call in calls.values)
        {
            if ( call.detail.status != FreeSmartphone.GSM.CallStatus.RELEASE &&
                 call.detail.status != FreeSmartphone.GSM.CallStatus.INCOMING )
            {
                num++;
            }
        }

        return num;
    }

    private int numberOfCallsWithStatus( FreeSmartphone.GSM.CallStatus status )
    {
        var num = 0;

        foreach (var call in calls.values)
        {
            if ( call.detail.status == status )
            {
                num++;
            }
        }

        return num;
    }
}

