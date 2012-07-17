/*
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
using FsoGsm.Constants;

internal const int CALL_STATUS_REFRESH_TIMEOUT = 3; // in seconds

/**
 * @class FsoGsm.GenericAtCallHandler
 */
public class FsoGsm.GenericAtCallHandler : FsoGsm.AbstractCallHandler
{
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
        var cmd = modem.data().atCommandCancelOutgoing;
        if ( cmd != null )
        {
            var c1 = new CustomAtCommand();
            var r1 = yield modem.processAtCommandAsync( c1, cmd );
            checkResponseOk( c1, r1 );
        }
        else
        {
            var c2 = modem.createAtCommand<V250H>( "H" );
            var r2 = yield modem.processAtCommandAsync( c2, c2.execute() );
            checkResponseOk( c2, r2 );
        }
    }

    protected override async void rejectIncomingWithId( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        assert( logger.debug( @"Rejecting incoming call with ID $id" ) );
        var cmd = modem.data().atCommandRejectIncoming;
        if ( cmd != null )
        {
            var c1 = new CustomAtCommand();
            var r1 = yield modem.processAtCommandAsync( c1, cmd );
            checkResponseOk( c1, r1 );
        }
        else
        {
            var c2 = modem.createAtCommand<V250H>( "H" );
            var r2 = yield modem.processAtCommandAsync( c2, c2.execute() );
            checkResponseOk( c2, r2 );
        }
    }

    public override void addSupplementaryInformation( string direction, string info )
    {
        supplementary = new FsoFramework.Pair<string,string>( direction, info );
    }

    protected override async void syncCallStatus()
    {
        inSyncCallStatus = true;

        try
        {
            assert( logger.debug( "Synchronizing call status" ) );
            var m = modem.createMediator<FsoGsm.CallListCalls>();
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
                        new GLib.HashTable<string,GLib.Variant>( str_hash, str_equal )
                    );

                    var ceer = modem.createAtCommand<PlusCEER>( "+CEER" );
                    var result = yield modem.processAtCommandAsync( ceer, ceer.execute() );
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

        inSyncCallStatus = false;
    }

    //
    // public API
    //

    public GenericAtCallHandler( FsoGsm.Modem modem )
    {
        base( modem );
    }

    //
    // DBus methods, delegated from the Call mediators
    //

    public override async void activate( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        validateCallId( id );

        if ( calls[id].detail.status != FreeSmartphone.GSM.CallStatus.INCOMING &&
             calls[id].detail.status != FreeSmartphone.GSM.CallStatus.HELD )
        {
            throw new FreeSmartphone.GSM.Error.CALL_NOT_FOUND( "No suitable call to activate found" );
        }

        if ( numberOfBusyCalls() == 0 ) // simple case
        {
            var cmd = modem.createAtCommand<V250D>( "A" );
            var response = yield modem.processAtCommandAsync( cmd, cmd.execute() );
            checkResponseOk( cmd, response );
        }
        else
        {
            // call is present and incoming or held
            var cmd2 = modem.createAtCommand<PlusCHLD>( "+CHLD" );
            var response2 = yield modem.processAtCommandAsync( cmd2, cmd2.issue( PlusCHLD.Action.HOLD_ALL_AND_ACCEPT_WAITING_OR_HELD ) );
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

        var cmd = modem.createAtCommand<V250D>( "D" );
        var response = yield modem.processAtCommandAsync( cmd, cmd.issue( number, ctype == "voice" ) );
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
        var cmd = modem.createAtCommand<PlusCHLD>( "+CHLD" );
        var response = yield modem.processAtCommandAsync( cmd, cmd.issue( PlusCHLD.Action.HOLD_ALL_AND_ACCEPT_WAITING_OR_HELD ) );
        checkResponseOk( cmd, response );
    }

    public override async void release( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        validateCallId( id );

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
            var cmd = modem.createAtCommand<PlusCHLD>( "+CHLD" );
            var response = yield modem.processAtCommandAsync( cmd, cmd.issue( PlusCHLD.Action.DROP_SPECIFIC_AND_ACCEPT_WAITING_OR_HELD, id ) );
            checkResponseOk( cmd, response );
        }
    }

    public override async void releaseAll() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = modem.createAtCommand<V250H>( "H" );
        yield modem.processAtCommandAsync( cmd, cmd.execute() );
        // no checkResponseOk, this call will always succeed
    }

    public override async void transfer() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        if ( numberOfCallsWithStatus( FreeSmartphone.GSM.CallStatus.ACTIVE ) == 0 &&
             // According to 22.091 section 5.8 it's possible that our network supports
             // transfering incoming calls too
             numberOfCallsWithStatus( FreeSmartphone.GSM.CallStatus.INCOMING ) == 0 )
            throw new FreeSmartphone.GSM.Error.CALL_NOT_FOUND( "No active call present" );

        if ( numberOfCallsWithStatus( FreeSmartphone.GSM.CallStatus.HELD ) == 0 )
            throw new FreeSmartphone.GSM.Error.CALL_NOT_FOUND( "No held call present" );

        var cmd = modem.createAtCommand<PlusCHLD>( "+CHLD" );
        var response = yield modem.processAtCommandAsync( cmd, cmd.issue( PlusCHLD.Action.DROP_SELF_AND_CONNECT_ACTIVE ) );
        checkResponseOk( cmd, response );

        // FIXME do we really need to call this here or can we skip it as call state
        // polling is always active as long as we have an active call?
        startTimeoutIfNecessary();
    }

    public override async void deflect( string number ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        if ( numberOfCallsWithStatus( FreeSmartphone.GSM.CallStatus.INCOMING ) == 0 &&
             numberOfCallsWithStatus( FreeSmartphone.GSM.CallStatus.HELD ) == 0 )
            throw new FreeSmartphone.GSM.Error.CALL_NOT_FOUND( "No active or held call present" );

        validatePhoneNumber( number );

        var cmd = modem.createAtCommand<PlusCTFR>( "+CTFR" );
        var response = yield modem.processAtCommandAsync( cmd, cmd.issue( number, determinePhoneNumberType( number ) ) );
        checkResponseOk( cmd, response );

        // FIXME do we really need to call this here or can we skip it as call state
        // polling is always active as long as we have an active call?
        startTimeoutIfNecessary();
    }

    public override async void conference( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        if ( numberOfCallsWithStatus( FreeSmartphone.GSM.CallStatus.ACTIVE ) != 0 )
        {
            if ( calls[id].detail.status == FreeSmartphone.GSM.CallStatus.HELD ||
                 calls[id].detail.status == FreeSmartphone.GSM.CallStatus.INCOMING )
            {
                throw new FreeSmartphone.GSM.Error.CALL_NOT_FOUND( "Specified call is not in held or incoming status" );
            }
        }
        else
        {
            throw new FreeSmartphone.GSM.Error.CALL_NOT_FOUND( "Without an active call we can't create a conference call" );
        }

        // If we deal with an incoming call we have to activate it first and hold our
        // current active call. If we deal with an active and an already held call we can
        // step through and add both to the conference.
        if ( calls[id].detail.status == FreeSmartphone.GSM.CallStatus.INCOMING )
        {
            var cmd = modem.createAtCommand<PlusCHLD>( "+CHLD" );
            var response = yield modem.processAtCommandAsync( cmd, cmd.issue( (PlusCHLD.Action) 2 ) );
            checkResponseOk( cmd, response );
        }

        var cmd = modem.createAtCommand<PlusCHLD>( "+CHLD" );
        var response = yield modem.processAtCommandAsync( cmd, cmd.issue( (PlusCHLD.Action) 3 ) );
        checkResponseOk( cmd, response );
    }

    public override async void join() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        if ( numberOfCallsWithStatus( FreeSmartphone.GSM.CallStatus.ACTIVE ) != 0 &&
             numberOfCallsWithStatus( FreeSmartphone.GSM.CallStatus.HELD ) != 0 )
        {
            throw new FreeSmartphone.GSM.Error.CALL_NOT_FOUND( "No active or hold calls to join" );
        }

        var cmd = modem.createAtCommand<PlusCHLD>( "+CHLD" );
        var response = yield modem.processAtCommandAsync( cmd, cmd.issue( (PlusCHLD.Action) 4 ));
        checkResponseOk( cmd, response );
    }
}

// vim:ts=4:sw=4:expandtab
