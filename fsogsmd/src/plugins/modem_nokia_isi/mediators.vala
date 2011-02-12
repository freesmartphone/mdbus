/*
 * Copyright (C) 2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
using FsoGsm;
using GIsiComm;

namespace NokiaIsi
{

/*
 * org.freesmartphone.Info
 */
public class IsiDeviceGetInformation : DeviceGetInformation
{
    /* revision, model, manufacturer, imei */
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        info = new GLib.HashTable<string,Variant>( str_hash, str_equal );

        NokiaIsi.isimodem.info.readManufacturer( ( error, msg ) => {
            info.insert( "manufacturer", error != ErrorCode.OK ? "<unknown>" : msg );
            run.callback();
        } );
        yield;

        NokiaIsi.isimodem.info.readModel( ( error, msg ) => {
            info.insert( "model", error != ErrorCode.OK ? "<unknown>" : msg );
            run.callback();
        } );
        yield;

        NokiaIsi.isimodem.info.readVersion( ( error, msg ) => {
            info.insert( "revision", error != ErrorCode.OK ? "<unknown>" : msg );
            run.callback();
        } );
        yield;

        NokiaIsi.isimodem.info.readSerial( ( error, msg ) => {
            info.insert( "imei", error != ErrorCode.OK ? "<unknown>" : msg );
            run.callback();
        } );
        yield;
    }
}

/*
 * org.freesmartphone.GSM.SIM
 */
public class IsiSimGetAuthStatus : SimGetAuthStatus
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        int isicode = 0;

        NokiaIsi.isimodem.simauth.queryStatus( (error, code) => {
            if ( error != ErrorCode.OK )
            {
                throw new FreeSmartphone.GSM.Error.DEVICE_FAILED( error.to_string() );
            }
            debug( @"code = %d, $code".printf( code ) );
            isicode = code;
            run.callback();
        } );
        yield;

        switch ( isicode )
        {
            case GIsiClient.SIMAuth.StatusResponseRunningType.NO_SIM:
                throw new FreeSmartphone.GSM.Error.SIM_NOT_PRESENT( "No SIM" );
                break;
            case GIsiClient.SIMAuth.StatusResponseRunningType.UNPROTECTED:
            case GIsiClient.SIMAuth.StatusResponseRunningType.AUTHORIZED:
                status = FreeSmartphone.GSM.SIMAuthStatus.READY;
                break;
            case GIsiClient.SIMAuth.StatusResponse.NEED_PIN:
                status = FreeSmartphone.GSM.SIMAuthStatus.PIN_REQUIRED;
                break;
            case GIsiClient.SIMAuth.StatusResponse.NEED_PUK:
                status = FreeSmartphone.GSM.SIMAuthStatus.PUK_REQUIRED;
                break;
            default:
                theModem.logger.warning( @"Unhandled ISI SIMAuth.Status $isicode" );
                status = FreeSmartphone.GSM.SIMAuthStatus.UNKNOWN;
                break;
        }
    }
}

public class IsiSimGetInformation : SimGetInformation
{
    /* imsi, issuer, phonebooks, slots [sms], used [sms] */
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        info = new GLib.HashTable<string,Variant>( str_hash, str_equal );

        NokiaIsi.isimodem.sim.readIMSI( ( error, msg ) => {
            info.insert( "imsi", error != ErrorCode.OK ? "<unknown>" : msg );
            run.callback();
        } );
        yield;

        NokiaIsi.isimodem.sim.readSPN( ( error, msg ) => {
            info.insert( "issuer", error != ErrorCode.OK ? "<unknown>" : msg );
            run.callback();
        } );
        yield;

        NokiaIsi.isimodem.sim.readHPLMN( ( error, msg ) => {
            info.insert( "hplmn", error != ErrorCode.OK ? "<unknown>" : msg );
            run.callback();
        } );
        yield;
    }
}

public class IsiSimSendAuthCode : SimSendAuthCode
{
    public override async void run( string pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        int isicode = 0;

        NokiaIsi.isimodem.simauth.sendPin( pin, ( error, code ) => {
            if ( error != ErrorCode.OK )
            {
                throw new FreeSmartphone.GSM.Error.DEVICE_FAILED( error.to_string() );
            }
            isicode = code;
            run.callback();
        } );
        yield;

        switch ( isicode )
        {
            case GIsiClient.SIMAuth.MessageType.SUCCESS_RESP:
                theModem.advanceToState( FsoGsm.Modem.Status.ALIVE_SIM_UNLOCKED );
                break;
            case GIsiClient.SIMAuth.ErrorType.NEED_PUK:
                throw new FreeSmartphone.GSM.Error.SIM_BLOCKED( @"ISI Code = $isicode" );
                break;
            default:
                throw new FreeSmartphone.GSM.Error.SIM_AUTH_FAILED( @"ISI Code = $isicode" );
                break;
        }
    }
}

/*
 * org.freesmartphone.GSM.Network
 */
public class IsiNetworkGetStatus : NetworkGetStatus
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        status = new GLib.HashTable<string,Variant>( str_hash, str_equal );

        var istatus = Network.ISI_RegStatus();

        NokiaIsi.isimodem.net.queryStatus( ( error, isistatus ) => {
            if ( error == ErrorCode.OK )
            {
                istatus = isistatus;
            }
            run.callback();
        } );
        yield;

        status.insert( "lac", istatus.lac );
        status.insert( "cid", istatus.cid );

        var regstatus = "<unknown>";
        switch ( istatus.status )
        {
            case GIsiClient.Network.RegistrationStatus.HOME:
                regstatus = "home";
                break;
            case GIsiClient.Network.RegistrationStatus.ROAM:
            case GIsiClient.Network.RegistrationStatus.ROAM_BLINK:
                regstatus = "roaming";
                break;
            case GIsiClient.Network.RegistrationStatus.NOSERV:
            case GIsiClient.Network.RegistrationStatus.NOSERV_NOTSEARCHING:
                regstatus = "unregistered";
                break;
            case GIsiClient.Network.RegistrationStatus.NOSERV_SEARCHING:
                regstatus = "searching";
                break;
            case GIsiClient.Network.RegistrationStatus.NOSERV_NOSIM:
            case GIsiClient.Network.RegistrationStatus.NOSERV_SIM_REJECTED_BY_NW:
                regstatus = "denied";
                break;
        }

        string regmode;
        switch ( istatus.mode )
        {
            case GIsiClient.Network.OperatorSelectMode.AUTOMATIC:
                regmode = "automatic";
                break;
            case GIsiClient.Network.OperatorSelectMode.MANUAL:
                regmode = "manual";
                break;
            /*
            case GIsiClient.Network.OperatorSelectMode.USER_RESELECTION:
                regmode = "automatic;manual";
                break;
            case GIsiClient.Network.OperatorSelectMode.NO_SELECTION:
                regmode = "unregister";
                break;
            */
            default:
                regmode = "unknown";
                break;
        }
        status.insert( "mode", regmode );

        status.insert( "registration", regstatus );
        status.insert( "band", istatus.band );
        status.insert( "code", istatus.mcc + istatus.mnc );
        status.insert( "provider", istatus.name );
        status.insert( "display", istatus.name );

        var technology = 0;
        if ( istatus.hsupa || istatus.hsdpa )
        {
            technology = 2;
        }
        else if ( istatus.egprs )
        {
            technology = 3;
        }

        status.insert( "act", Constants.instance().networkProviderActToString( technology ) );

        NokiaIsi.isimodem.net.queryStrength( ( error, strength ) => {
            if ( error == ErrorCode.OK )
            {
                status.insert( "strength", strength );
            }
            run.callback();
        } );
        yield;
    }
}

public class IsiNetworkListProviders : NetworkListProviders
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var p = new FreeSmartphone.GSM.NetworkProvider[] {};

        NokiaIsi.isimodem.net.listProviders( ( error, operators ) => {
            if ( error == ErrorCode.OK )
            {
                for ( int i = 0; i < operators.length; ++i )
                {
                    p += FreeSmartphone.GSM.NetworkProvider( Constants.instance().networkProviderStatusToString( operators[i].status ),
                                                             operators[i].name,
                                                             operators[i].name,
                                                             operators[i].mcc + operators[i].mnc,
                                                             Constants.instance().networkProviderActToString( operators[i].technology ) );
                }
            }
            run.callback();
        } );
        yield;

        providers = p;
    }
}

public class IsiNetworkGetSignalStrength : NetworkGetSignalStrength
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        NokiaIsi.isimodem.net.queryStrength( ( error, strength ) => {
            if ( error == ErrorCode.OK )
            {
                this.signal = strength;
                run.callback();
            }
            else
            {
                throw new FreeSmartphone.GSM.Error.DEVICE_FAILED( "Unknown ISI Error" );
            }
        } );
        yield;
    }
}

public class IsiNetworkRegister : NetworkRegister
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        NokiaIsi.isimodem.net.registerAutomatic( true, (error) => {
            if ( error == ErrorCode.OK )
            {
                run.callback();
            }
            else
            {
                throw new FreeSmartphone.GSM.Error.DEVICE_FAILED( "Unknown ISI Error" );
            }
        } );
        yield;
    }
}

/*
 * org.freesmartphone.GSM.Call
 */

public class IsiCallActivate : CallActivate
{
    public override async void run( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        yield theModem.callhandler.activate( id );
    }
}

public class IsiCallHoldActive : CallHoldActive
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        yield theModem.callhandler.hold();
    }
}

public class IsiCallInitiate : CallInitiate
{
    public override async void run( string number, string ctype ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        validatePhoneNumber( number );
        id = yield theModem.callhandler.initiate( number, ctype );
    }
}

public class IsiCallRelease : CallRelease
{
    public override async void run( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        yield theModem.callhandler.release( id );
    }
}

public class IsiCallReleaseAll : CallReleaseAll
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        yield theModem.callhandler.releaseAll();
    }
}

public class IsiCallSendDtmf : CallSendDtmf
{
    public override async void run( string tones ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        NokiaIsi.isimodem.call.sendTonesOnVoiceCall( 1, tones, ( error ) => {
            if ( error == ErrorCode.OK )
            {
                run.callback();
            }
            else
            {
                throw new FreeSmartphone.GSM.Error.DEVICE_FAILED( "Unknown ISI Error" );
            }
        } );
        yield;
    }
}

/*
 * Register Mediators
 */
static void registerMediators( HashMap<Type,Type> mediators )
{
    mediators[ typeof(DeviceGetInformation) ]            = typeof( IsiDeviceGetInformation );

    mediators[ typeof(SimGetAuthStatus) ]                = typeof( IsiSimGetAuthStatus );
    mediators[ typeof(SimGetInformation) ]               = typeof( IsiSimGetInformation );
    mediators[ typeof(SimSendAuthCode) ]                 = typeof( IsiSimSendAuthCode );

    mediators[ typeof(NetworkGetStatus) ]                = typeof( IsiNetworkGetStatus );
    mediators[ typeof(NetworkGetSignalStrength) ]        = typeof( IsiNetworkGetSignalStrength );
    mediators[ typeof(NetworkListProviders) ]            = typeof( IsiNetworkListProviders );
    mediators[ typeof(NetworkRegister) ]                 = typeof( IsiNetworkRegister );

    mediators[ typeof(CallActivate) ]                    = typeof( IsiCallActivate );
    mediators[ typeof(CallHoldActive) ]                  = typeof( IsiCallHoldActive );
    mediators[ typeof(CallInitiate) ]                    = typeof( IsiCallInitiate );
    mediators[ typeof(CallRelease) ]                     = typeof( IsiCallRelease );
    mediators[ typeof(CallReleaseAll) ]                  = typeof( IsiCallReleaseAll );
    mediators[ typeof(CallSendDtmf) ]                    = typeof( IsiCallSendDtmf );

    theModem.logger.debug( "Nokia ISI mediators registered" );
}

} /* namespace NokiaIsi */
