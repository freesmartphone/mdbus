/*
 * Copyright (C) 2009-2012 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

    protected FsoGsm.Modem modem { get; private set; }

    public BaseUnsolicitedResponseHandler( FsoGsm.Modem modem )
    {
        this.modem = modem;

        urcs = new HashMap<string,UnsolicitedResponseHandlerFuncWrapper>();
        urcpdus = new HashMap<string,UnsolicitedResponsePduHandlerFuncWrapper>();
    }

    public override string repr()
    {
        return "";
    }

    protected void registerUrc( string prefix, UnsolicitedResponseHandlerFunc func )
    {
        assert( logger.debug( @"Registering URC '$prefix'" ) );
        urcs[prefix] = new UnsolicitedResponseHandlerFuncWrapper() { func=func };
    }

    protected void registerUrcPdu( string prefix, UnsolicitedResponsePduHandlerFunc func )
    {
        urcpdus[prefix] = new UnsolicitedResponsePduHandlerFuncWrapper() { func=func };
    }

    public bool dispatch( string prefix, string rhs, string? pdu = null )
    {
        assert( logger.debug( @"Dispatching AT unsolicited '$prefix', '$rhs'" ) );

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
    }
}

public class FsoGsm.AtUnsolicitedResponseHandler : FsoGsm.BaseUnsolicitedResponseHandler
{
    //
    // public API
    //

    public AtUnsolicitedResponseHandler( FsoGsm.Modem modem )
    {
        base( modem );

        registerUrc( "+CALA", plusCALA );
        registerUrc( "+CCWA", plusCCWA );
        registerUrc( "+CGEV", plusCGEV );
        registerUrc( "+CGREG", plusCGREG );
        registerUrc( "+CIEV", plusCIEV );
        registerUrc( "+CLIP", plusCLIP );
        registerUrc( "+CMTI", plusCMTI );
        registerUrc( "+CREG", plusCREG );
        registerUrc( "+CRING", plusCRING );
        registerUrc( "+CSSI", plusCSSI );
        registerUrc( "+CSSU", plusCSSU );
        registerUrc( "+CTZV", plusCTZV );
        registerUrc( "+CUSD", plusCUSD );
        registerUrc( "NO CARRIER", no_carrier );

        registerUrcPdu( "+CBM", plusCBM );
        registerUrcPdu( "+CDS", plusCDS );
        registerUrcPdu( "+CMT", plusCMT );
    }

    //
    // simple URCs

    public virtual void plusCALA( string prefix, string rhs )
    {
        // send dbus signal
        var obj = modem.theDevice<FreeSmartphone.Device.RealtimeClock>();
        obj.alarm( 0 );
    }

    public virtual void plusCCWA( string prefix, string rhs )
    {
        // The call waiting parameters are irrelevant, as we're going to pull them
        // immediately via +CLCC anyways. Note that we force type to be
        // 'VOICE' since call waiting does only apply to voice calls.
        modem.callhandler.handleIncomingCall( new FsoGsm.CallInfo.with_ctype( "VOICE" ) );
    }

    public virtual void plusCGEV( string prefix, string rhs )
    {
        //FIXME: Implement
    }

    public virtual void plusCGREG( string prefix, string rhs )
    {
        triggerUpdateNetworkStatus( modem );
    }

    public virtual void plusCIEV( string prefix, string rhs )
    {
        var ciev = modem.createAtCommand<PlusCIEV>( "+CIEV" );
        if ( ciev.validateUrc( @"$prefix: $rhs" ) == Constants.AtResponse.VALID )
        {
            logger.warning( @"Received unhandled +CIEV $(ciev.value1), $(ciev.value2)" );
        }
        else
        {
            logger.warning( @"Received invalid +CIEV message $rhs. Please report" );
        }
    }

    public virtual void plusCLIP( string prefix, string rhs )
    {
    }

    public virtual void plusCMTI( string prefix, string rhs )
    {
        var cmti = modem.createAtCommand<PlusCMTI>( "+CMTI" );
        if ( cmti.validateUrc( @"$prefix: $rhs" ) == Constants.AtResponse.VALID )
        {
            modem.smshandler.handleIncomingSmsOnSim( cmti.index );
        }
        else
        {
            logger.warning( @"Received invalid +CMTI message $rhs. Please report" );
        }
    }

    public virtual void plusCREG( string prefix, string rhs )
    {
        triggerUpdateNetworkStatus( modem );
    }

    public virtual void plusCRING( string prefix, string rhs )
    {
        modem.callhandler.handleIncomingCall( new FsoGsm.CallInfo.with_ctype( rhs ) );
    }

    public virtual void plusCSSI( string prefix, string rhs )
    {
        var cssi = modem.createAtCommand<PlusCSSI>( "+CSSI" );
        if ( cssi.validateUrc( @"$prefix: $rhs" ) == Constants.AtResponse.VALID )
        {
            modem.callhandler.addSupplementaryInformation( Constants.callDirectionToString( 0 ), Constants.cssiCodeToString( cssi.value ) );
        }
        else
        {
            logger.warning( @"Received invalid +CSSI message $rhs. Please report" );
        }
    }

    public virtual void plusCSSU( string prefix, string rhs )
    {
        var cssu = modem.createAtCommand<PlusCSSU>( "+CSSU" );
        if ( cssu.validateUrc( @"$prefix: $rhs" ) == Constants.AtResponse.VALID )
        {
            modem.callhandler.addSupplementaryInformation( Constants.callDirectionToString( 1 ), Constants.cssuCodeToString( cssu.value ) );
        }
        else
        {
            logger.warning( @"Received invalid +CSSU message $rhs. Please report" );
        }
    }

    public virtual void plusCTZV( string prefix, string rhs )
    {
        // FIXME: +CTZV should be remembered

        var tzoffset = int.parse( rhs );
        if ( tzoffset < 0 )
        {
            logger.warning( @"Receive invalid +CTZV message $rhs. Please report" );
        }
        else
        {
            var utcoffset = Constants.ctzvToTimeZone( tzoffset );
            logger.info( @"Received time zone report from GSM: $utcoffset minutes" );
            var data = modem.data();
            data.networkTimeReport.setZone( utcoffset );
        }
    }

    public virtual void plusCUSD( string prefix, string rhs )
    {
        var cusd = modem.createAtCommand<PlusCUSD>( "+CUSD" );
        if ( cusd.validateUrc( @"$prefix: $rhs" ) == Constants.AtResponse.VALID )
        {
#if DEBUG
            debug( @"CUSD MODE: $(cusd.mode), RESULT: $(cusd.result), CODE: $(cusd.code)" );
#endif
            var obj = modem.theDevice<FreeSmartphone.GSM.Network>();
            obj.incoming_ussd( (FreeSmartphone.GSM.UssdStatus)cusd.mode, cusd.result );
        }
        else
        {
            logger.warning( @"Received invalid +CUSD message $rhs. Please report" );
        }
    }

    public virtual void no_carrier( string prefix, string rhs )
    {
        //FIXME: Implement
    }

    //
    // URCs w/ PDU

    public virtual void plusCDS( string prefix, string rhs, string pdu )
    {
        var cds = modem.createAtCommand<PlusCDS>( "+CDS" );
        if ( cds.validateUrcPdu( { @"$prefix: $rhs", pdu } ) == Constants.AtResponse.VALID )
        {
            modem.smshandler.handleIncomingSmsReport( cds.hexpdu, cds.tpdulen );
        }
        else
        {
            logger.warning( @"Received invalid +CDS message $rhs. Please report" );
        }
    }

    public virtual void plusCBM( string prefix, string rhs, string pdu )
    {
        var cbm = modem.createAtCommand<PlusCBM>( "+CBM" );
        if ( cbm.validateUrcPdu( { @"$prefix: $rhs", pdu } ) == Constants.AtResponse.VALID )
        {
            Cb.Message? cb = Cb.Message.newFromHexPdu( cbm.hexpdu, cbm.tpdulen );
            if ( cb == null )
            {
                logger.warning( @"Error while decoding cell broadcast message w/ PDU $(cbm.hexpdu) $(cbm.tpdulen). Please report" );
            }
            else
            {
                string lang;
                var text = cb.decode_all( out lang );

                var obj = modem.theDevice<FreeSmartphone.GSM.CB>();
                obj.incoming_cell_broadcast( text, lang, new GLib.HashTable<string,Variant>( GLib.str_hash, GLib.str_equal ) );
            }
        }
        else
        {
            logger.warning( @"Received invalid +CBM message $rhs. Please report" );
        }
    }

    public virtual void plusCMT( string prefix, string rhs, string pdu )
    {
        var cmt = modem.createAtCommand<PlusCMT>( "+CMT" );
        if ( cmt.validateUrcPdu( { @"$prefix: $rhs", pdu } ) == Constants.AtResponse.VALID )
        {
            modem.smshandler.handleIncomingSms( cmt.hexpdu, cmt.tpdulen );
        }
        else
        {
            logger.warning( @"Received invalid +CMT message $rhs. Please report" );
        }
    }
}

// vim:ts=4:sw=4:expandtab
