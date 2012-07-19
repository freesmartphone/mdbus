/*
 * Copyright (C) 2010-2012 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

public GLib.HashTable<string,Variant> isiRegStatusToFsoRegStatus( Network.ISI_RegStatus istatus )
{
    var status = new GLib.HashTable<string,Variant>( str_hash, str_equal );

    if ( istatus.status == GIsiClient.Network.RegistrationStatus.HOME ||
         istatus.status == GIsiClient.Network.RegistrationStatus.ROAM ||
         istatus.status == GIsiClient.Network.RegistrationStatus.ROAM_BLINK )
    {
        status.insert( "lac", istatus.lac );
        status.insert( "cid", istatus.cid );
        status.insert( "code", istatus.mcc + istatus.mnc );
        string name = istatus.name ?? "";
        status.insert( "network", istatus.network ?? name );
        status.insert( "provider", istatus.name ?? name );
        status.insert( "display", istatus.name ?? name );
    }

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

    var technology = 0;
    if ( istatus.hsupa || istatus.hsdpa )
    {
        technology = 2;
    }
    else if ( istatus.egprs )
    {
        technology = 3;
    }

    status.insert( "act", Constants.networkProviderActToString( technology ) );

    return status;
}

/*
 * org.freesmartphone.GSM.Network
 */
public class IsiNetworkGetStatus : NetworkGetStatus
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var istatus = Network.ISI_RegStatus();

        NokiaIsi.isimodem.net.queryStatus( ( error, isistatus ) => {
            if ( error == ErrorCode.OK )
            {
                istatus = isistatus;
            }
            run.callback();
        } );
        yield;

        status = isiRegStatusToFsoRegStatus( istatus );

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
                    p += FreeSmartphone.GSM.NetworkProvider( Constants.networkProviderStatusToString( operators[i].status ),
                                                             operators[i].name,
                                                             operators[i].name,
                                                             operators[i].mcc + operators[i].mnc,
                                                             Constants.networkProviderActToString( operators[i].technology ) );
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
    static bool force = false;

    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        /*
        NokiaIsi.isimodem.net.queryRat( ( error, result ) => {
            debug( "error = %d", error );
            runInBackground.callback();
        } );
        yield;

        NokiaIsi.isimodem.net.queryStatus( ( error, result ) => {
            debug( "error = %d", error );
            runInBackground.callback();
        } );
        yield;
        */

        ErrorCode e = ErrorCode.OK;

        NokiaIsi.isimodem.net.registerAutomatic( force, ( error ) => {
            e = error;
            run.callback();
        } );
        yield;

        if ( e != ErrorCode.OK )
        {
            throw new FreeSmartphone.GSM.Error.DEVICE_FAILED( "ISI Error %d".printf( e ) );
        }

        force = !force;
    }
}

public class IsiNetworkRegisterWithProvider : NetworkRegisterWithProvider
{
    public override async void run( string mccmnc ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        ErrorCode e = ErrorCode.OK;

        NokiaIsi.isimodem.net.registerManual( mccmnc[0:3], mccmnc[3:5], ( error ) => {
            e = error;
            run.callback();
        } );
        yield;

        if ( e != ErrorCode.OK )
        {
            throw new FreeSmartphone.GSM.Error.DEVICE_FAILED( "ISI Error %d".printf( e ) );
        }
    }
}

} // namespace NokiaIsi

// vim:ts=4:sw=4:expandtab
