/*
 * Copyright (C) 2009-2012 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *               2012 Simon Busch <morphis@gravedo.de>
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

internal const int CALL_STATUS_REFRESH_TIMEOUT = 3; // in seconds

public abstract interface FsoGsm.ICallHandler : FsoFramework.AbstractObject
{
    /**
     * Call this, when the network has indicated an incoming call.
     **/
    public abstract void handleIncomingCall( FsoGsm.CallInfo call_info );

    /**
     * Call this, when the network has indicated an connecting call
     **/
    public abstract void handleConnectingCall( FsoGsm.CallInfo call_info );

    /**
     * Call this, when the network has indicated an ending call
     **/
    public abstract void handleEndingCall( FsoGsm.CallInfo call_info );

    /**
     * Call this, when the network has indicated a supplementary service indication.
     **/
    public abstract void addSupplementaryInformation( string direction, string info );

    /**
     * Call Actions
     **/
    public abstract async void activate( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
    public abstract async int  initiate( string number, string ctype ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
    public abstract async void hold() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
    public abstract async void release( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
    public abstract async void releaseAll() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
    public abstract async void transfer() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
    public abstract async void deflect( string number ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
    public abstract async void conference( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
    public abstract async void join() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public class FsoGsm.NullCallHandler : FsoGsm.ICallHandler, FsoFramework.AbstractObject
{
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

    public async void activate( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }

    public async int  initiate( string number, string ctype ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        return 0;
    }

    public async void hold() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }

    public async void release( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }

    public async void releaseAll() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }

    public async void transfer() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }

    public async void deflect( string number ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }

    public async void conference( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }

    public async void join() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }

    public override string repr()
    {
        return @"<>";
    }
}

public class FsoGsm.CallHandler : FsoGsm.ICallHandler, FsoFramework.AbstractObject
{
    private ICallDriver driver;
    private bool inSyncCallStatus;
    private uint timeout;
    private FsoGsm.Call[] calls;
    private FsoFramework.Pair<string,string> supplementary;
    private FsoGsm.Modem modem { get; private set; }

    construct
    {
        calls = new FsoGsm.Call[Constants.CALL_INDEX_MAX+1] {};
        for ( int i = Constants.CALL_INDEX_MIN; i != Constants.CALL_INDEX_MAX; ++i )
        {
            calls[i] = new Call.newFromId( i );
            calls[i].status_changed.connect( ( id, status, properties ) => {
                var obj = modem.theDevice<FreeSmartphone.GSM.Call>();
                obj.call_status( id, status, properties );
            } );
        }
    }

    //
    // private
    //

    private void validateCallId( int id ) throws FreeSmartphone.Error
    {
        if ( id < 1 || id > Constants.CALL_INDEX_MAX )
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Call index needs to be within [ 1, %d ]".printf( (int)Constants.CALL_INDEX_MAX) );
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
                num++;
        }
        return num;
    }

    private int numberOfCallsWithSpecificStatus( FreeSmartphone.GSM.CallStatus[] status )
    {
        var num = 0;
        for ( int i = Constants.CALL_INDEX_MIN; i != Constants.CALL_INDEX_MAX; ++i )
        {
            if ( calls[i].detail.status in status )
                num++;
        }
        return num;
    }

    private int lowestOfCallsWithStatus( FreeSmartphone.GSM.CallStatus status )
    {
        for ( int i = Constants.CALL_INDEX_MIN; i != Constants.CALL_INDEX_MAX; ++i )
        {
            if ( calls[i].detail.status == status )
                return i;
        }
        return 0;
    }

    private void startTimeoutIfNecessary()
    {
        onTimeout();
        if ( timeout == 0 )
            timeout = GLib.Timeout.add_seconds( CALL_STATUS_REFRESH_TIMEOUT, onTimeout );
    }

    private bool onTimeout()
    {
        if ( inSyncCallStatus )
        {
            assert( logger.debug( "Synchronizing call status not done yet... ignoring" ) );
        }
        else
        {
            syncCallStatus.begin();
        }

        return true;
    }

    private async void syncCallStatus()
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

                    /*
                    var ceer = modem.createAtCommand<PlusCEER>( "+CEER" );
                    var result = yield modem.processAtCommandAsync( ceer, ceer.execute() );
                    if ( ceer.validate( result ) == Constants.AtResponse.VALID )
                    {
                        detail.properties.insert( "cause", ceer.reason );
                    }
                    */

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

    public CallHandler( ICallDriver driver )
    {
        this.driver = driver;
    }

    public async void activate( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        validateCallId( id );

        if ( calls[id].detail.status != FreeSmartphone.GSM.CallStatus.INCOMING &&
             calls[id].detail.status != FreeSmartphone.GSM.CallStatus.HELD )
        {
            throw new FreeSmartphone.GSM.Error.CALL_NOT_FOUND( "No suitable call to activate found" );
        }

        if ( numberOfBusyCalls() != 0 )
            throw new FreeSmartphone.GSM.Error.CALL_NOT_FOUND( "System busy" );

        yield driver.activate();
    }

    public async int initiate( string number, string ctype ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var num = lowestOfCallsWithStatus( FreeSmartphone.GSM.CallStatus.RELEASE );
        if ( num == 0 )
            throw new FreeSmartphone.GSM.Error.CALL_NOT_FOUND( "System busy" );

        yield driver.dial( number, ctype );

        startTimeoutIfNecessary();

        return num;
    }

    public async void hold() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        if ( numberOfCallsWithStatus( FreeSmartphone.GSM.CallStatus.ACTIVE ) == 0 )
            throw new FreeSmartphone.GSM.Error.CALL_NOT_FOUND( "No active call present" );

        if ( numberOfCallsWithStatus( FreeSmartphone.GSM.CallStatus.INCOMING ) > 0 )
            throw new FreeSmartphone.GSM.Error.CALL_NOT_FOUND( "Call incoming. Can't hold active calls without activating" );
    }

    public async void release( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        validateCallId( id );

        if ( calls[id].detail.status == FreeSmartphone.GSM.CallStatus.RELEASE )
            throw new FreeSmartphone.GSM.Error.CALL_NOT_FOUND( "No suitable call to release found" );

        if ( calls[id].detail.status == FreeSmartphone.GSM.CallStatus.OUTGOING )
        {
            yield driver.cancel_outgoing_with_id( id );
            return;
        }

        if ( numberOfCallsWithStatus( FreeSmartphone.GSM.CallStatus.INCOMING ) == 1 && calls[id].detail.status == FreeSmartphone.GSM.CallStatus.INCOMING )
        {
            yield driver.reject_incoming_with_id( id );
            return;
        }
        else
        {
            yield driver.release( id );
        }
    }

    public async void releaseAll() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        if ( numberOfCallsWithSpecificStatus( new FreeSmartphone.GSM.CallStatus[] {
                FreeSmartphone.GSM.CallStatus.INCOMING, FreeSmartphone.GSM.CallStatus.OUTGOING,
                FreeSmartphone.GSM.CallStatus.HELD, FreeSmartphone.GSM.CallStatus.ACTIVE } ) == 0 )
        {
            throw new FreeSmartphone.GSM.Error.CALL_NOT_FOUND( "No call to release available" );
        }

        yield driver.hangup_all();
    }

    public async void transfer() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        if ( numberOfCallsWithStatus( FreeSmartphone.GSM.CallStatus.ACTIVE ) == 0 &&
             // According to 22.091 section 5.8 it's possible that our network supports
             // transfering incoming calls too
             numberOfCallsWithStatus( FreeSmartphone.GSM.CallStatus.INCOMING ) == 0 )
            throw new FreeSmartphone.GSM.Error.CALL_NOT_FOUND( "No active call present" );

        if ( numberOfCallsWithStatus( FreeSmartphone.GSM.CallStatus.HELD ) == 0 )
            throw new FreeSmartphone.GSM.Error.CALL_NOT_FOUND( "No held call present" );

        yield driver.transfer();
    }

    public async void deflect( string number ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        if ( numberOfCallsWithStatus( FreeSmartphone.GSM.CallStatus.INCOMING ) == 0 &&
             numberOfCallsWithStatus( FreeSmartphone.GSM.CallStatus.HELD ) == 0 )
            throw new FreeSmartphone.GSM.Error.CALL_NOT_FOUND( "No active or held call present" );

        validatePhoneNumber( number );

        yield driver.deflect( number );
    }

    public async void conference( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
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

        yield driver.create_conference();
    }

    public async void join() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        if ( numberOfCallsWithStatus( FreeSmartphone.GSM.CallStatus.ACTIVE ) != 0 &&
             numberOfCallsWithStatus( FreeSmartphone.GSM.CallStatus.HELD ) != 0 )
        {
            throw new FreeSmartphone.GSM.Error.CALL_NOT_FOUND( "No active or hold calls to join" );
        }

        yield driver.join();
    }

    public void addSupplementaryInformation( string direction, string info )
    {
    }

    public void handleIncomingCall( FsoGsm.CallInfo call_info )
    {
        startTimeoutIfNecessary();
    }

    public void handleConnectingCall( FsoGsm.CallInfo call_info )
    {
    }

    public void handleEndingCall( FsoGsm.CallInfo call_info )
    {
    }

    public override string repr()
    {
        return @"<>";
    }
}

// vim:ts=4:sw=4:expandtab
