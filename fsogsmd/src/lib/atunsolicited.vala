/**
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

public delegate void UnsolicitedResponseHandlerFunc( string prefix, string rhs );
public delegate void UnsolicitedResponsePduHandlerFunc( string prefix, string rhs, string pdu );

class UnsolicitedResponseHandlerFuncWrapper
{
    public UnsolicitedResponseHandlerFunc func;
}

class UnsolicitedResponsePduHandlerFuncWrapper
{
    public UnsolicitedResponsePduHandlerFunc func;
}

/**
 * Unsolicited Interface, Base Class, and At Version
 **/

public abstract interface FsoGsm.UnsolicitedResponseHandler : FsoFramework.AbstractObject
{
    public abstract bool dispatch( string prefix, string rhs, string? pdu = null );
}

public class FsoGsm.BaseUnsolicitedResponseHandler : FsoGsm.UnsolicitedResponseHandler, FsoFramework.AbstractObject
{
    private HashMap<string,UnsolicitedResponseHandlerFuncWrapper> urcs;
    private HashMap<string,UnsolicitedResponsePduHandlerFuncWrapper> urcpdus;

    construct
    {
        urcs = new HashMap<string,UnsolicitedResponseHandlerFuncWrapper>();
        urcpdus = new HashMap<string,UnsolicitedResponsePduHandlerFuncWrapper>();
    }

    public override string repr()
    {
        return "";
    }

    protected void registerUrc( string prefix, UnsolicitedResponseHandlerFunc func )
    {
        assert( logger.debug( @"registering URC '$prefix'" ) );
        urcs[prefix] = new UnsolicitedResponseHandlerFuncWrapper() { func=func };
    }

    protected void registerUrcPdu( string prefix, UnsolicitedResponsePduHandlerFunc func )
    {
        urcpdus[prefix] = new UnsolicitedResponsePduHandlerFuncWrapper() { func=func };
    }

    public bool dispatch( string prefix, string rhs, string? pdu = null )
    {
        assert( logger.debug( @"dispatching AT unsolicited '$prefix', '$rhs'" ) );

        if ( pdu == null )
        {
            var urcwrapper = urcs[prefix];
            if ( urcwrapper != null )
            {
                urcwrapper.func( prefix, rhs );
                return true;
            }
            else
            {
                return false;
            }
        }
        else
        {
            var urcwrapper = urcpdus[prefix];
            if ( urcwrapper != null )
            {
                urcwrapper.func( prefix, rhs, pdu );
                return true;
            }
            else
            {
                return false;
            }
        }
        return false; // not handled
    }
}

public class FsoGsm.AtUnsolicitedResponseHandler : FsoGsm.BaseUnsolicitedResponseHandler
{
    //
    // public API
    //
    public AtUnsolicitedResponseHandler()
    {
        registerUrc( "+CALA", plusCALA );
        registerUrc( "+CCWA", plusCCWA );
        registerUrc( "+CIEV", plusCIEV );
        registerUrc( "+CMTI", plusCMTI );
        registerUrc( "+CREG", plusCREG );
        registerUrc( "+CRING", plusCRING );
    }

    public virtual void plusCALA( string prefix, string rhs )
    {
        // send dbus signal
        var obj = theModem.theDevice<FreeSmartphone.Device.RealtimeClock>();
        obj.alarm( 0 );
    }

    public virtual void plusCCWA( string prefix, string rhs )
    {
        // The call waiting parameters are irrelevant, as we're going to pull them
        // immediately via +CLCC anyways. Note that we force type to be
        // 'VOICE' since call waiting does only apply to voice calls.
        theModem.callhandler.handleIncomingCall( "VOICE" );
    }

    public virtual void plusCIEV( string prefix, string rhs )
    {
        //FIXME: Implement
    }

    public virtual void plusCREG( string prefix, string rhs )
    {
        triggerUpdateNetworkStatus();
    }

    public virtual void plusCRING( string prefix, string rhs )
    {
        theModem.callhandler.handleIncomingCall( rhs );
    }

    public virtual void plusCMTI( string prefix, string rhs )
    {
        var cmti = theModem.createAtCommand<PlusCMTI>( "+CMTI" );
        if ( cmti.validateUrc( @"$prefix: $rhs" ) == Constants.AtResponse.VALID )
        {
            theModem.smshandler.handleIncomingSmsOnSim( cmti.index );
        }
        else
        {
            logger.warning( @"Received invalid +CMTI message $rhs. Please report" );
        }
    }


}
