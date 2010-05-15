/*
 * Copyright (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

internal const int CALL_STATUS_REFRESH_TIMEOUT = 3; // in seconds

/**
 * @class FsoGsm.GenericAtCallHandler
 */
public class FsoGsm.GenericAtCallHandler : FsoGsm.AbstractCallHandler
{
    protected uint timeout;
    protected FsoGsm.Call[] calls;

    protected FsoFramework.Pair<string,string> supplementary;

    construct
    {
        calls = new FsoGsm.Call[Constants.CALL_INDEX_MAX+1] {};
        for ( int i = Constants.CALL_INDEX_MIN; i != Constants.CALL_INDEX_MAX; ++i )
        {
            calls[i] = new Call.newFromId( i );
        }
    }

    private int numberOfBusyCalls()
    {
        var num = 0;
        for ( int i = Constants.CALL_INDEX_MIN; i != Constants.CALL_INDEX_MAX; ++i )
        {
            if ( calls[i].detail.status != FreeSmartphone.GSM.CallStatus.RELEASE && calls[i].detail.status != FreeSmartphone.GSM.CallStatus.INCOMING )
            {
                num++;
            }
        }
        return num;
    }

    private int numberOfCallsWithStatus( FreeSmartphone.GSM.CallStatus status )
    {
        var num = 0;
        for ( int i = Constants.CALL_INDEX_MIN; i != Constants.CALL_INDEX_MAX; ++i )
        {
            if ( calls[i].detail.status == status )
            {
                num++;
            }
        }
        return num;
    }

    private int lowestOfCallsWithStatus( FreeSmartphone.GSM.CallStatus status )
    {
        for ( int i = Constants.CALL_INDEX_MIN; i != Constants.CALL_INDEX_MAX; ++i )
        {
            if ( calls[i].detail.status == status )
            {
                return i;
            }
        }
        return 0;
    }

    public override string repr()
    {
        return "<>";
    }

    //
    // protected API
    //
    protected override async void cancelOutgoingWithId( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        assert( logger.debug( @"Cancelling outgoing call with ID $id" ) );
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
    }

    protected override async void rejectIncomingWithId( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        assert( logger.debug( @"Rejecting incoming call with ID $id" ) );
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
    }

    protected override void startTimeoutIfNecessary()
    {
        onTimeout();
        if ( timeout == 0 )
        {
            timeout = GLib.Timeout.add_seconds( CALL_STATUS_REFRESH_TIMEOUT, onTimeout );
        }
    }

    protected bool onTimeout()
    {
        syncCallStatus.begin();
        return true;
    }

    public override void addSupplementaryInformation( string direction, string info )
    {
        supplementary = new FsoFramework.Pair<string,string>( direction, info );
    }

    protected async void syncCallStatus()
    {
        try
        {
            assert( logger.debug( "Synchronizing call status" ) );
            var m = theModem.createMediator<FsoGsm.CallListCalls>();
            yield m.run();

            // workaround for https://bugzilla.gnome.org/show_bug.cgi?id=585847
            var length = 0;
            foreach ( var c in m.calls )
            {
                length++;
            }
            // </workaround>

            assert( logger.debug( @"$(length) calls known in the system" ) );

            // stop timer if there are no more calls
            if ( length == 0 )
            {
                assert( logger.debug( "call status idle -> stopping updater" ) );
                Source.remove( timeout );
                timeout = 0;
            }

            if ( supplementary != null )
            {
                // add supplementary information to incoming or outgoing
                foreach ( var ca in m.calls )
                {
                    var direction = ca.properties.lookup( "direction" ).get_string();
                    if ( direction == supplementary.first )
                    {
                        ca.properties.insert( "service", supplementary.second );
                    }
                }
                supplementary = null;
            }

            // visit all busy (incoming,outgoing,held,active) calls to send updates...
            var visited = new bool[Constants.CALL_INDEX_MAX+1];
            foreach ( var call in m.calls )
            {
                calls[call.id].update( call );
                visited[call.id] = true;
            }

            // ...and synthesize updates for (now) released calls
            for ( int i = Constants.CALL_INDEX_MIN; i != Constants.CALL_INDEX_MAX; ++i )
            {
                if ( ! visited[i] && calls[i].detail.status != FreeSmartphone.GSM.CallStatus.RELEASE )
                {
                    var detail = FreeSmartphone.GSM.CallDetail(
                        i,
                        FreeSmartphone.GSM.CallStatus.RELEASE,
                        new GLib.HashTable<string,GLib.Value?>( str_hash, str_equal )
                    );

                    var ceer = theModem.createAtCommand<PlusCEER>( "+CEER" );
                    var result = yield theModem.processAtCommandAsync( ceer, ceer.execute() );
                    if ( ceer.validate( result ) == Constants.AtResponse.VALID )
                    {
                        detail.properties.insert( "cause", ceer.reason );
                    }

                    calls[i].update( detail );
                }
            }
        }
        catch ( GLib.Error e )
        {
            logger.error( @"Can't synchronize call status: $(e.message)" );
        }
    }

    //
    // DBus methods, delegated from the Call mediators
    //
    public override async void activate( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        if ( id < 1 || id > Constants.CALL_INDEX_MAX )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Call index needs to be within [ 1, %d ]".printf( (int)Constants.CALL_INDEX_MAX) );
        }
        if ( calls[id].detail.status != FreeSmartphone.GSM.CallStatus.INCOMING && calls[id].detail.status != FreeSmartphone.GSM.CallStatus.HELD )
        {
            throw new FreeSmartphone.GSM.Error.CALL_NOT_FOUND( "No suitable call to activate found" );
        }

        if ( numberOfBusyCalls() == 0 ) // simple case
        {
            var cmd = theModem.createAtCommand<V250D>( "A" );
            var response = yield theModem.processAtCommandAsync( cmd, cmd.execute() );
            checkResponseOk( cmd, response );
        }
        else
        {
            // call is present and incoming or held
            var cmd2 = theModem.createAtCommand<PlusCHLD>( "+CHLD" );
            var response2 = yield theModem.processAtCommandAsync( cmd2, cmd2.issue( PlusCHLD.Action.HOLD_ALL_AND_ACCEPT_WAITING_OR_HELD ) );
            checkResponseOk( cmd2, response2 );
        }
    }

    public override async int initiate( string number, string ctype ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var num = lowestOfCallsWithStatus( FreeSmartphone.GSM.CallStatus.RELEASE );
        if ( num == 0 )
        {
            throw new FreeSmartphone.GSM.Error.CALL_NOT_FOUND( "System busy" );
        }

        var cmd = theModem.createAtCommand<V250D>( "D" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( number, ctype == "voice" ) );
        checkResponseOk( cmd, response );

        startTimeoutIfNecessary();

        return num;
    }

    public override async void hold() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        if ( numberOfCallsWithStatus( FreeSmartphone.GSM.CallStatus.ACTIVE ) == 0 )
        {
            throw new FreeSmartphone.GSM.Error.CALL_NOT_FOUND( "No active call present" );
        }
        if ( numberOfCallsWithStatus( FreeSmartphone.GSM.CallStatus.INCOMING ) > 0 )
        {
            throw new FreeSmartphone.GSM.Error.CALL_NOT_FOUND( "Call incoming. Can't hold active calls without activating" );
        }
        var cmd = theModem.createAtCommand<PlusCHLD>( "+CHLD" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( PlusCHLD.Action.HOLD_ALL_AND_ACCEPT_WAITING_OR_HELD ) );
        checkResponseOk( cmd, response );
    }

    public override async void release( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        if ( id < 1 || id > Constants.CALL_INDEX_MAX )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Call index needs to be within [ 1, %d ]".printf( (int)Constants.CALL_INDEX_MAX) );
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
        if ( numberOfCallsWithStatus( FreeSmartphone.GSM.CallStatus.INCOMING ) == 1 && calls[id].detail.status == FreeSmartphone.GSM.CallStatus.INCOMING )
        {
            yield rejectIncomingWithId( id );
            return;
        }
        else
        {
            var cmd = theModem.createAtCommand<PlusCHLD>( "+CHLD" );
            var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( PlusCHLD.Action.DROP_SPECIFIC_AND_ACCEPT_WAITING_OR_HELD, id ) );
            checkResponseOk( cmd, response );
        }
    }

    public override async void releaseAll() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<V250H>( "H" );
        yield theModem.processAtCommandAsync( cmd, cmd.execute() );
        // no checkResponseOk, this call will always succeed
    }
}
