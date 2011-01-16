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

        NokiaIsi.modem.isidevice.query_manufacturer( ( error, msg ) => {
            info.insert( "manufacturer", error ? "unknown" : msg );
            run.callback();
        } );
        yield;

        NokiaIsi.modem.isidevice.query_model( ( error, msg ) => {
            info.insert( "model", error ? "unknown" : msg );
            run.callback();
        } );
        yield;

        NokiaIsi.modem.isidevice.query_revision( ( error, msg ) => {
            info.insert( "revision", error ? "unknown" : msg );
            run.callback();
        } );
        yield;

        NokiaIsi.modem.isidevice.query_serial( ( error, msg ) => {
            info.insert( "imei", error ? "unknown" : msg );
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
    // public FreeSmartphone.GSM.SIMAuthStatus status;
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        ISI.SIMAuth.Status isicode = 0;

        NokiaIsi.modem.isisimauth.request_status( ( code ) => {
            debug( @"code = %d, $code".printf( code ) );
            isicode = code;
            run.callback();
        } );
        yield;

        switch ( isicode )
        {
			case ISI.SIMAuth.Status.NO_SIM:
                throw new FreeSmartphone.GSM.Error.SIM_NOT_PRESENT( "No SIM" );
                break;
			case ISI.SIMAuth.Status.UNPROTECTED:
			case ISI.SIMAuth.Status.AUTHORIZED:
                status = FreeSmartphone.GSM.SIMAuthStatus.READY;
                break;
			case ISI.SIMAuth.Status.NEED_NONE:
                status = FreeSmartphone.GSM.SIMAuthStatus.READY;
                break;
			case ISI.SIMAuth.Status.NEED_PIN:
                status = FreeSmartphone.GSM.SIMAuthStatus.PIN_REQUIRED;
                break;
			case ISI.SIMAuth.Status.NEED_PUK:
                status = FreeSmartphone.GSM.SIMAuthStatus.PUK_REQUIRED;
                break;
            default:
                theModem.logger.warning( @"Unhandled ISI SIMAuth.Status $isicode" );
                status = FreeSmartphone.GSM.SIMAuthStatus.UNKNOWN;
                break;
        }
    }
}

public class IsiSimSendAuthCode : SimSendAuthCode
{
    public override async void run( string pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        ISI.SIMAuth.Answer isicode = 0;

        NokiaIsi.modem.isisimauth.set_pin( pin, ( code ) => {
            isicode = code;
            run.callback();
        } );
        yield;

        switch ( isicode )
        {
			case ISI.SIMAuth.Answer.OK:
                theModem.advanceToState( FsoGsm.Modem.Status.ALIVE_SIM_UNLOCKED );
                break;
            case ISI.SIMAuth.Answer.ERR_NEED_PUK:
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

        var istatus = ISI.Network.Status();

        NokiaIsi.modem.isinetwork.request_status( ( error, isistatus ) => {
            if ( !error )
            {
                istatus = isistatus;
            }
            run.callback();
        } );
        yield;

        status.insert( "lac", "%04X".printf( istatus.lac ) );
        status.insert( "cid", "%04X".printf( istatus.cid ) );
        var regstatus = "unknown";
        switch ( istatus.status )
        {
            case ISI.Network.RegistrationStatus.HOME:
                regstatus = "home";
                break;
            case ISI.Network.RegistrationStatus.ROAM:
            case ISI.Network.RegistrationStatus.ROAM_BLINK:
                regstatus = "roaming";
                break;
            case ISI.Network.RegistrationStatus.NOSERV:
            case ISI.Network.RegistrationStatus.NOSERV_NOTSEARCHING:
                regstatus = "unregistered";
                break;
            case ISI.Network.RegistrationStatus.NOSERV_SEARCHING:
                regstatus = "searching";
                break;
            case ISI.Network.RegistrationStatus.NOSERV_NOSIM:
            case ISI.Network.RegistrationStatus.NOSERV_SIM_REJECTED_BY_NW:
                regstatus = "denied";
                break;
        }
        status.insert( "registration", regstatus );
        status.insert( "act", Constants.instance().networkProviderActToString( istatus.technology ) );

        NokiaIsi.modem.isinetwork.current_operator( ( error, operator ) => {
            if ( !error )
            {
                status.insert( "display", operator.name );
                status.insert( "provider", operator.name );
                status.insert( "code", operator.mcc + operator.mnc );
                run.callback();
            }
        } );
        yield;

        NokiaIsi.modem.isinetwork.request_strength( ( error, strength ) => {
            if ( !error )
            {
                status.insert( "strength", strength );
                run.callback();
            }
        } );
        yield;
    }
}

public class IsiNetworkListProviders : NetworkListProviders
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var p = new FreeSmartphone.GSM.NetworkProvider[] {};

        NokiaIsi.modem.isinetwork.list_operators( ( error, operators ) => {
            if ( !error )
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
    private int s;

    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
	    NokiaIsi.modem.isinetwork.request_strength( ( error, strength ) => {
		     if ( !error )
			 {
				 this.s = strength;
				 run.callback();
			 }
		} );
        yield;

		signal = this.s;
	}
}

/*
 * Register Mediators
 */
static void registerMediators( HashMap<Type,Type> mediators )
{
    mediators[ typeof(DeviceGetInformation) ]            = typeof( IsiDeviceGetInformation );

    mediators[ typeof(SimGetAuthStatus) ]                = typeof( IsiSimGetAuthStatus );
    mediators[ typeof(SimSendAuthCode) ]                 = typeof( IsiSimSendAuthCode );

    mediators[ typeof(NetworkGetStatus) ]                = typeof( IsiNetworkGetStatus );
    mediators[ typeof(NetworkGetSignalStrength) ]        = typeof( IsiNetworkGetSignalStrength );
    mediators[ typeof(NetworkListProviders) ]            = typeof( IsiNetworkListProviders );

    theModem.logger.debug( "Nokia ISI mediators registered" );
}

} /* namespace NokiaIsi */
