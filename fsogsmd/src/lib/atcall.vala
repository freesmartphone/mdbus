/**
 * Copyright (C) 2009 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
 * @class FsoGsm.Call
 **/
public class FsoGsm.Call
{
    public XFreeSmartphone.GSM.CallDetail detail;

    public Call.newFromDetail( XFreeSmartphone.GSM.CallDetail detail )
    {
        this.detail = detail;
    }

    public Call.newFromId( int id )
    {
        detail.id = id;
        detail.status = "release";
        detail.properties = new GLib.HashTable<string,GLib.Value?>( str_hash, str_equal );
    }

    public bool update( XFreeSmartphone.GSM.CallDetail detail )
    {
        assert( this.detail.id == detail.id );
        if ( this.detail.status != detail.status )
        {
            notify( detail );
            return true;
        }
        if ( this.detail.properties.size() != detail.properties.size() )
        {
            notify( detail );
            return true;
        }
        /*
        var iter = GLib.HashTableIter<string,GLib.Value?>( this.detail.properties );
        string key; Value? v;
        while ( iter.next( out key, out v ) )
        {
            var v2 = detail.properties.lookup( key );
            if ( v2 == null || v != v2 )
            {
                notify( detail );
                return;
            }
        }
        */
        return false; // nothing happened
    }

    public void notify( XFreeSmartphone.GSM.CallDetail detail )
    {
        var obj = theModem.theDevice<XFreeSmartphone.GSM.Call>();
        obj.call_status( detail.id, detail.status, detail.properties );
        this.detail = detail;
    }

}

/**
 * @interface FsoGsm.CallHandler
 **/
public abstract interface FsoGsm.CallHandler : FsoFramework.AbstractObject
{
    /**
     * Call this, when the network has indicated an incoming call.
     **/
    public abstract void handleIncomingCall( string ctype );

    public abstract async void activate( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error;
    public abstract async int  initiate( string number, string ctype ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error;
    public abstract async void hold() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error;
    public abstract async void release( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error;
    public abstract async void releaseAll() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error;
    /*
    public abstract async void conference() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error;
    public abstract async void join() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error;
    */
}

/**
 * @class FsoGsm.AbstractCallHandler
 **/
public abstract class FsoGsm.AbstractCallHandler : FsoGsm.Mediator, FsoGsm.CallHandler, FsoFramework.AbstractObject
{
    public void handleIncomingCall( string ctype )
    {
        startTimeoutIfNecessary();
    }

    protected abstract void startTimeoutIfNecessary();

    public abstract async void activate( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error;
    public abstract async int  initiate( string number, string ctype ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error;
    public abstract async void hold() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error;
    public abstract async void release( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error;
    public abstract async void releaseAll() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error;
}

/**
 * @class FsoGsm.GenericAtCallHandler
 */
public class FsoGsm.GenericAtCallHandler : FsoGsm.AbstractCallHandler
{
    protected uint timeout;
    protected FsoGsm.Call[] calls;

    construct
    {
        calls = new FsoGsm.Call[Constants.CALL_INDEX_MAX+1] {};
        for ( int i = 1; i != Constants.CALL_INDEX_MAX; ++i )
        {
            calls[i] = new Call.newFromId( i );
        }
    }

    private int numberOfBusyCalls()
    {
        var num = 0;
        for ( int i = 1; i != Constants.CALL_INDEX_MAX; ++i )
        {
            if ( calls[i].detail.status != "release" && calls[i].detail.status != "incoming" )
            {
                num++;
            }
        }
        return num;
    }

    private int numberOfCallsWithStatus( string status )
    {
        var num = 0;
        for ( int i = 1; i != Constants.CALL_INDEX_MAX; ++i )
        {
            if ( calls[i].detail.status == status )
            {
                num++;
            }
        }
        return num;
    }

    private int lowestOfCallsWithStatus( string status )
    {
        for ( int i = 1; i != Constants.CALL_INDEX_MAX; ++i )
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

    protected async void syncCallStatus()
    {
        assert( logger.debug( "synchronizing call status" ) );
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

        // visit all busy (incoming,outgoing,held,active) calls to send updates...
        var visited = new bool[Constants.CALL_INDEX_MAX+1];
        foreach ( var call in m.calls )
        {
            calls[call.id].update( call );
            visited[call.id] = true;
        }

        // ...and synthesize updates for (now) released calls
        for ( int i = 0; i != Constants.CALL_INDEX_MAX; ++i )
        {
            if ( ! visited[i] && calls[i].detail.status != "release" )
            {
                var detail = XFreeSmartphone.GSM.CallDetail();
                detail.id = i;
                detail.status = "release";
                detail.properties = new GLib.HashTable<string,GLib.Value?>( str_hash, str_equal );

                var ceer = theModem.createAtCommand<PlusCEER>( "+CEER" );
                var result = yield theModem.processCommandAsync( ceer, ceer.execute() );
                if ( ceer.validate( result ) == Constants.AtResponse.VALID )
                {
                    //FIXME: Use after https://bugzilla.gnome.org/show_bug.cgi?id=599568 has been FIXED.
                    //var cause = Value( typeof(string) );
                    //cause = ceer.value
                    //detail.properties.insert( "cause", ceer.value );
                }

                calls[i].update( detail );
            }
        }
    }

    //
    // DBus methods, delegated from the Call mediators
    //
    public override async void activate( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        if ( id < 1 || id > Constants.CALL_INDEX_MAX )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Call index needs to be within [ 1, %d ]".printf( (int)Constants.CALL_INDEX_MAX) );
        }
        if ( calls[id].detail.status != "incoming" && calls[id].detail.status != "held" )
        {
            throw new FreeSmartphone.GSM.Error.CALL_NOT_FOUND( "No suitable call to activate found" );
        }

        if ( numberOfBusyCalls() == 0 ) // simple case
        {
            var cmd = theModem.createAtCommand<V250D>( "A" );
            var response = yield theModem.processCommandAsync( cmd, cmd.execute() );
            checkResponseOk( cmd, response );
        }
        else
        {
            // call is present and incoming or held
            var cmd2 = theModem.createAtCommand<PlusCHLD>( "+CHLD" );
            var response2 = yield theModem.processCommandAsync( cmd2, cmd2.issue( PlusCHLD.Action.HOLD_ALL_AND_ACCEPT_WAITING_OR_HELD ) );
            checkResponseOk( cmd2, response2 );
        }
    }

    public override async int initiate( string number, string ctype ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var num = lowestOfCallsWithStatus( "release" );
        if ( num == 0 )
        {
            throw new FreeSmartphone.GSM.Error.CALL_NOT_FOUND( "System busy" );
        }

        var cmd = theModem.createAtCommand<V250D>( "D" );
        var response = yield theModem.processCommandAsync( cmd, cmd.issue( number, ctype == "voice" ) );
        checkResponseOk( cmd, response );

        startTimeoutIfNecessary();

        return num;
    }

    public override async void hold() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        if ( numberOfCallsWithStatus( "active" ) == 0 )
        {
            throw new FreeSmartphone.GSM.Error.CALL_NOT_FOUND( "No active call present" );
        }
        if ( numberOfCallsWithStatus( "incoming" ) > 0 )
        {
            throw new FreeSmartphone.GSM.Error.CALL_NOT_FOUND( "Call incoming. Can't hold active calls without activating" );
        }
        var cmd = theModem.createAtCommand<PlusCHLD>( "+CHLD" );
        var response = yield theModem.processCommandAsync( cmd, cmd.issue( PlusCHLD.Action.HOLD_ALL_AND_ACCEPT_WAITING_OR_HELD ) );
        checkResponseOk( cmd, response );
    }

    public override async void release( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        if ( id < 1 || id > Constants.CALL_INDEX_MAX )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Call index needs to be within [ 1, %d ]".printf( (int)Constants.CALL_INDEX_MAX) );
        }
        if ( calls[id].detail.status == "release" )
        {
            throw new FreeSmartphone.GSM.Error.CALL_NOT_FOUND( "No suitable call to release found" );
        }
        var cmd = theModem.createAtCommand<PlusCHLD>( "+CHLD" );
        var response = yield theModem.processCommandAsync( cmd, cmd.issue( PlusCHLD.Action.DROP_SPECIFIC_AND_ACCEPT_WAITING_OR_HELD, id ) );
        checkResponseOk( cmd, response );
    }

    public override async void releaseAll() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var cmd = theModem.createAtCommand<V250H>( "H" );
        var response = yield theModem.processCommandAsync( cmd, cmd.execute() );
        // no checkResponseOk, this call will always succeed
    }
}
