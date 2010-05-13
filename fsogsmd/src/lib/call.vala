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

/**
 * @class FsoGsm.Call
 **/
public class FsoGsm.Call
{
    public FreeSmartphone.GSM.CallDetail detail;

    public Call.newFromDetail( FreeSmartphone.GSM.CallDetail detail )
    {
        this.detail = detail;
    }

    public Call.newFromId( int id )
    {
        detail.id = id;
        detail.status = FreeSmartphone.GSM.CallStatus.RELEASE;
        detail.properties = new GLib.HashTable<string,GLib.Value?>( str_hash, str_equal );
    }

    public bool update( FreeSmartphone.GSM.CallDetail detail )
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

    public void notify( FreeSmartphone.GSM.CallDetail detail )
    {
        var obj = theModem.theDevice<FreeSmartphone.GSM.Call>();
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
    /*
    public abstract async void conference() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
    public abstract async void join() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
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

    public abstract void addSupplementaryInformation( string direction, string info );

    protected abstract void startTimeoutIfNecessary();

    public abstract async void activate( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
    public abstract async int  initiate( string number, string ctype ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
    public abstract async void hold() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
    public abstract async void release( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
    public abstract async void releaseAll() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;

    /**
     * Override this to implement modem-specific cancelling of an outgoing call
     **/
    protected abstract async void cancelOutgoingWithId( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}
