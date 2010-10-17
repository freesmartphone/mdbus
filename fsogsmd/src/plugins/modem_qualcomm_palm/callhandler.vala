/*
 * Copyright (C) 2010 Simon Busch <morphis@gravedo.de>
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
        try
        {
            var cmds = MsmModemAgent.instance().commands;
            
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
                cmds.answer_call( id );
            }
            else
            {
                // call is present and incoming or held
                cmds.manage_calls( Msmcomm.CallCommandType.HOLD_ALL_AND_ACCEPT_WAITING_OR_HELD, 0 );
            }
        }
        catch ( Msmcomm.Error err0 )
        {
            MsmUtil.handleMsmcommErrorMessage( err0 );
        }
        catch ( DBus.Error err1 )
        {
        }
    }

    /**
     * Initiate a call with a specified number; can be a voice or data call
     **/
    public override async int initiate( string number, string ctype ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        int num = 0;
        
        try 
        {
            // Initiate call to the selected number
            var cmds = MsmModemAgent.instance().commands;
            cmds.dial_call(number, Msmcomm.RuntimeData.block_number);
        
            startTimeoutIfNecessary();
        }
        catch ( Msmcomm.Error err0 )
        {
            MsmUtil.handleMsmcommErrorMessage( err0 );
        }
        catch ( DBus.Error err1 )
        {
        }
        
        return num;
    }

    /**
     * Hold all already active call
     **/
    public override async void hold() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
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
            
            var cmds = MsmModemAgent.instance().commands;
            cmds.manage_calls(Msmcomm.CallCommandType.HOLD_ALL_AND_ACCEPT_WAITING_OR_HELD, 0);
        }
        catch ( Msmcomm.Error err0 )
        {
            MsmUtil.handleMsmcommErrorMessage( err0 );
        }
        catch ( DBus.Error err1 )
        {
        }
    }

    /**
     * Release an already active call
     **/
    public override async void release( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
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
                var cmds = MsmModemAgent.instance().commands;
                cmds.manage_calls( Msmcomm.CallCommandType.DROP_SPECIFIC_AND_ACCEPT_WAITING_OR_HELD, id );
            }
        }
        catch ( Msmcomm.Error err0 )
        {
            MsmUtil.handleMsmcommErrorMessage( err0 );
        }
        catch ( DBus.Error err1 )
        {
        }
    }

    public override async void releaseAll() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        #if 0 
        var cmd = theModem.createAtCommand<V250H>( "H" );
        yield theModem.processAtCommandAsync( cmd, cmd.execute() );
        // no checkResponseOk, this call will always succeed
        #endif
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
        
        #if 0
        var cmd = theModem.data().atCommandCancelOutgoing;
        if ( cmd != null )
        {
            var c1 = new CustomAtCommand();
            var r1 = yield theModem.processAtCommandAsync( c1, cmd );
            checkResponseOk( c1, r1 );
        }
        else
        {
            var c2 = theModem.createAtCommand<V250H>( "H" );
            var r2 = yield theModem.processAtCommandAsync( c2, c2.execute() );
            checkResponseOk( c2, r2 );
        }
        #endif
    }

    protected override async void rejectIncomingWithId( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        assert( logger.debug( @"Rejecting incoming call with ID $id" ) );
        
        #if 0
        var cmd = theModem.data().atCommandRejectIncoming;
        if ( cmd != null )
        {
            var c1 = new CustomAtCommand();
            var r1 = yield theModem.processAtCommandAsync( c1, cmd );
            checkResponseOk( c1, r1 );
        }
        else
        {
            var c2 = theModem.createAtCommand<V250H>( "H" );
            var r2 = yield theModem.processAtCommandAsync( c2, c2.execute() );
            checkResponseOk( c2, r2 );
        }
        #endif
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

