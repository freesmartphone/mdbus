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
        detail.properties = new GLib.HashTable<string,GLib.Variant>( str_hash, str_equal );
    }

    public bool update_status( FreeSmartphone.GSM.CallStatus new_status )
    {
        var result = false;

        if ( this.detail.status != new_status )
        {
            this.detail.status = new_status;
            notify( this.detail );
            result = true;
        }

        return result;
    }

    public bool update( FreeSmartphone.GSM.CallDetail detail )
    {
        assert( this.detail.id == detail.id );
        var result = false;

        // Something has changed and we should notify somebody about his?
        if ( this.detail.status != detail.status )
        {
            notify( detail );
            result = true;
        }
        else if ( this.detail.properties.size() != detail.properties.size() )
        {
            notify( detail );
            result = true;
        }

        /*
        var iter = GLib.HashTableIter<string,GLib.Variant>( this.detail.properties );
        string key; Variant? v;
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

        return result; 
    }

    public void notify( FreeSmartphone.GSM.CallDetail detail )
    {
        var obj = theModem.theDevice<FreeSmartphone.GSM.Call>();
        obj.call_status( detail.id, detail.status, detail.properties );
        this.detail = detail;
    }
}

/**
 * @class FsoGsm.CallInfo
 **/
public class FsoGsm.CallInfo : GLib.Object
{
    construct
    {
        cinfo = new GLib.HashTable<string,GLib.Variant>( str_hash, str_equal );
    }

    public CallInfo()
    {
    }

    public CallInfo.with_ctype( string ctype )
    {
        this.ctype = ctype;
    }

    public string ctype { get; set; default = ""; }
    public int id { get; set; default = 0; }
    public GLib.HashTable<string, GLib.Variant?> cinfo;
}

/**
 * @interface FsoGsm.CallHandler
 **/
public abstract interface FsoGsm.CallHandler : FsoFramework.AbstractObject
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
    /*
    public abstract async void conference() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
    public abstract async void join() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
    */
}

/**
 * @class FsoGsm.NullCallHandler
 **/
public class FsoGsm.NullCallHandler : FsoGsm.CallHandler, FsoFramework.AbstractObject
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

    public override string repr()
    {
        return @"<>";
    }
}

/**
 * @class FsoGsm.AbstractCallHandler
 **/
public abstract class FsoGsm.AbstractCallHandler : FsoGsm.Mediator, FsoGsm.CallHandler, FsoFramework.AbstractObject
{
    public virtual void handleIncomingCall( FsoGsm.CallInfo call_info )
    {
        startTimeoutIfNecessary();
    }

    public virtual void handleConnectingCall( FsoGsm.CallInfo call_info )
    {
    }

    public virtual void handleEndingCall( FsoGsm.CallInfo call_info )
    {
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
    /**
     * Override this to implement modem-specific rejecting of an incoming call
     **/
    protected abstract async void rejectIncomingWithId( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

// vim:ts=4:sw=4:expandtab
