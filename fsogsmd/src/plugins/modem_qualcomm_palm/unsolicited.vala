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
using FsoGsm;

public delegate void MsmUnsolicitedResponseHandlerFunc( Msmcomm.Message urc );

class MsmUnsolicitedResponseHandlerFuncWrapper
{
    public MsmUnsolicitedResponseHandlerFunc func;
}

/**
 * MSM Unsolicited Base Class and Handler
 **/

public class MsmBaseUnsolicitedResponseHandler : FsoFramework.AbstractObject
{
    private HashMap<Msmcomm.EventType,MsmUnsolicitedResponseHandlerFuncWrapper> urcs;

    public MsmBaseUnsolicitedResponseHandler()
    {
        urcs = new HashMap<Msmcomm.EventType,MsmUnsolicitedResponseHandlerFuncWrapper>();
    }

    public override string repr()
    {
        return "";
    }

    protected void registerUrc( Msmcomm.EventType urctype, MsmUnsolicitedResponseHandlerFunc func )
    {
        assert( logger.debug( @"registering URC '$urctype'" ) );
        urcs[urctype] = new MsmUnsolicitedResponseHandlerFuncWrapper() { func=func };
    }

    public bool dispatch( Msmcomm.EventType urctype, Msmcomm.Message urc )
    {
        assert( logger.debug( @"dispatching AT unsolicited $(Msmcomm.eventTypeToString( urctype ))" ) );

        var urcwrapper = urcs[urctype];
        if ( urcwrapper != null )
        {
            urcwrapper.func( urc );
            return true;
        }
        else
        {
            return false;
        }
    }
}

public class MsmUnsolicitedResponseHandler : MsmBaseUnsolicitedResponseHandler
{
    //
    // public API
    //
    public MsmUnsolicitedResponseHandler()
    {
        registerUrc( Msmcomm.EventType.SIM_PIN1_ENABLED, handleSimPin1Enabled );
        registerUrc( Msmcomm.EventType.SIM_PIN1_VERIFIED, handleSimPin1Verified );
        registerUrc( Msmcomm.EventType.NETWORK_STATE_INFO, handleNetworkStateInfo );
    }

    public virtual void handleSimPin1Enabled( Msmcomm.Message urc )
    {
        updateMsmSimAuthStatus( FreeSmartphone.GSM.SIMAuthStatus.PIN_REQUIRED );

        var msmModem = theModem as QualcommPalm.Modem;
        msmModem.openAuxChannel();
    }

    public virtual void handleSimPin1Verified( Msmcomm.Message urc )
    {
        updateMsmSimAuthStatus( FreeSmartphone.GSM.SIMAuthStatus.READY );
    }

    public virtual void handleNetworkStateInfo( Msmcomm.Message urc )
    {
        var status = new GLib.HashTable<string,Value?>( str_hash, str_equal );

        unowned Msmcomm.Unsolicited.NetworkStateInfo netinfo = (Msmcomm.Unsolicited.NetworkStateInfo) urc;

        status.insert( "mode", "automatic" );
        status.insert( "strength", (int)netinfo.rssi );
        status.insert( "registration", "home" );
        status.insert( "lac", "unknown" );
        status.insert( "cid", "unknown" );
        status.insert( "provider", netinfo.operator_name );
        status.insert( "display", netinfo.operator_name );
        status.insert( "code", "unknown" );
        status.insert( "pdp.registration", netinfo.gprs_attached.to_string() );
        status.insert( "pdp.lac", "unknown" );
        status.insert( "pdp.cid", "unknown" );

        var obj = FsoGsm.theModem.theDevice<FreeSmartphone.GSM.Network>();
        obj.status( status );
    }
}
