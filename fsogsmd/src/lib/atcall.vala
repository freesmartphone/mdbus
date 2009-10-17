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

internal const int MAXIMUM_NUMBER_OF_CALLS = 10; // 3 would be more like it, but hey... let's play safe ;)

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
    public abstract async void initiate( string number, string ctype ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error;
    public abstract async void releaseAll() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error;
    /*
    public abstract async void activate( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error;
    public abstract async void release( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error;
    public abstract async void hold( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error;
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

    public virtual async void activate( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
    }
    public virtual async void initiate( string number, string ctype ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
    }
    public virtual async void releaseAll() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
    }
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
        calls = new FsoGsm.Call[MAXIMUM_NUMBER_OF_CALLS] {};
        for ( int i = 1; i < MAXIMUM_NUMBER_OF_CALLS; ++i )
        {
            calls[i] = new Call.newFromId( i );
        }
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

        // visit all calls and synthesize updates for released ones
        var visited = new bool[MAXIMUM_NUMBER_OF_CALLS];
        foreach ( var call in m.calls )
        {
            calls[call.id].update( call );
            visited[call.id] = true;
        }

        for ( int i = 0; i < MAXIMUM_NUMBER_OF_CALLS; ++i )
        {
            if ( ! visited[i] )
            {
                //FIXME: This leads to a (harmless) assertion
                calls[i].update( new Call.newFromId( i ).detail );
            }
        }
    }

    //
    // DBus methods, delegated from the Call mediators
    //

    public override async void activate( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var cmd = theModem.createAtCommand<V250D>( "A" );
        var response = yield theModem.processCommandAsync( cmd, cmd.execute() );
        checkResponseOk( cmd, response );
    }

    public override async void initiate( string number, string ctype ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var cmd = theModem.createAtCommand<V250D>( "D" );
        var response = yield theModem.processCommandAsync( cmd, cmd.issue( number, ctype == "voice" ) );
        checkResponseOk( cmd, response );

        startTimeoutIfNecessary();
    }

    /*
    public override async void holdActive()
    {
    }
    */

    public override async void releaseAll() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var cmd = theModem.createAtCommand<V250H>( "H" );
        var response = yield theModem.processCommandAsync( cmd, cmd.execute() );
        // no checkResponseOk, this call will always succeed
    }

    /*

    public override async void release( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var cmd = theModem.createAtCommand<V250D>( "D" );
        var response = yield theModem.processCommandAsync( cmd, cmd.issue( number, ctype == "voice" ) );
    }
    */
}
