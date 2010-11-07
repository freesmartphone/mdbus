/*
 * Copyright (C) 2010 Simon Busch <morphis@gravedo.de>
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
                yield cmds.answer_call( id );
            }
            else
            {
                // call is present and incoming or held
                yield cmds.execute_call_sups_command( Msmcomm.CallCommandType.HOLD_ALL_AND_ACCEPT_WAITING_OR_HELD, 0 );
            }
        }
        catch ( Msmcomm.Error err0 )
        {
            MsmUtil.handleMsmcommErrorMessage( err0 );
        }
        catch ( DBusError, IOError err1 )
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
            yield cmds.originate_call(number, Msmcomm.RuntimeData.block_number);

            // Wait until the modem reports the origination of our new call
            var ma = MsmModemAgent.instance();
            GLib.Variant response = yield ma.waitForUnsolicitedResponse( Msmcomm.UrcType.CALL_ORIGINATION );
            var call_info = Msmcomm.CallInfo.from_variant( response );
        
            startTimeoutIfNecessary();
        }
        catch ( Msmcomm.Error err0 )
        {
            MsmUtil.handleMsmcommErrorMessage( err0 );
        }
        catch ( DBusError, IOError err1 )
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
            yield cmds.execute_call_sups_command(Msmcomm.CallCommandType.HOLD_ALL_AND_ACCEPT_WAITING_OR_HELD, 0);
        }
        catch ( Msmcomm.Error err0 )
        {
            MsmUtil.handleMsmcommErrorMessage( err0 );
        }
        catch ( DBusError, IOError err1 )
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
                yield cmds.execute_call_sups_command( Msmcomm.CallCommandType.DROP_SPECIFIC_AND_ACCEPT_WAITING_OR_HELD, id );
            }
        }
        catch ( Msmcomm.Error err0 )
        {
            MsmUtil.handleMsmcommErrorMessage( err0 );
        }
        catch ( DBusError, IOError err1 )
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
        // Create a new call with status == RELEASE with the supplied id
        var new_call = new FsoGsm.Call.newFromId( call_info.id );
        
        // Update the created call so it is now an incomming one
        var empty_properties = new GLib.HashTable<string,GLib.Variant>( str_hash, str_equal );
        var call_detail = new FreeSmartphone.GSM.CallDetail( call_info.id, 
                                                             FreeSmartphone.GSM.CallStatus.INCOMING, 
                                                             empty_properties );
        new_call.update( call_detail );
        
        // Save call for later processing
        calls.set( call_info.id, new_call );
    }
    
    /**
     * Handle an connecting call
     **/
    public override void handleConnectingCall( FsoGsm.CallInfo call_info )
    {
        // Do we have an call with the supplied id?
        if ( calls.has_key( call_info.id ) )
        {
            // Call is connecting, so it's next state is ACTIVE
            var call = calls.get( call_info.id );
            call.update_status( FreeSmartphone.GSM.CallStatus.ACTIVE );
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
        // Do we have an call with the supplied id?
        if ( calls.has_key( call_info.id ) )
        {
            // Call is connecting, so it's next state is ACTIVE
            var call = calls.get( call_info.id );
            call.update_status( FreeSmartphone.GSM.CallStatus.RELEASE );
            calls.remove( call_info.id );
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
            var cmds = MsmModemAgent.instance().commands;
            yield cmds.end_call( id );
        }
        catch ( Msmcomm.Error err0 )
        {
            MsmUtil.handleMsmcommErrorMessage( err0 );
        }
        catch ( DBusError, IOError err1 )
        {
        }
    }

    protected override async void rejectIncomingWithId( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        assert( logger.debug( @"Rejecting incoming call with ID $id" ) );
        
        try
        {
            // NOTE currently we reject an incomming call by dropping all calls or send a busy
            // signal when we have no active calls. Maybe there is another way in msmcomm
            // to do reject an incomming call but we currently don't know about.
            var cmds = MsmModemAgent.instance().commands;
            var cmd_type = Msmcomm.CallCommandType.DROP_ALL_OR_SEND_BUSY;
            yield cmds.execute_call_sups_command( cmd_type, 0 );
        }
        catch ( Msmcomm.Error err0 )
        {
            MsmUtil.handleMsmcommErrorMessage( err0 );
        }
        catch ( DBusError, IOError err1 )
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

