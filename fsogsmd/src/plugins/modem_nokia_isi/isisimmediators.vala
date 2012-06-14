/*
 * Copyright (C) 2010-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *               2011 Klaus 'mrmoku' Kurzmann <mok@fluxnetz.de>
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

using FsoGsm;
using GIsiComm;

/*
 * org.freesmartphone.GSM.SIM
 */

namespace NokiaIsi
{

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

            case GIsiClient.SIMAuth.StatusResponse.INIT:
                status = FreeSmartphone.GSM.SIMAuthStatus.READY;
                debug( "warning, SIMAuth Status = INIT..." );
                break;


            default:
                modem.logger.warning( @"Unhandled ISI SIMAuth.Status $isicode" );
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
            case GIsiClient.SIMAuth.IndicationType.OK:
                modem.advanceToState( FsoGsm.Modem.Status.ALIVE_SIM_UNLOCKED );
                break;
            case GIsiClient.SIMAuth.IndicationType.PUK:
                throw new FreeSmartphone.GSM.Error.SIM_BLOCKED( @"ISI Code = $isicode" );
                break;
            default:
                throw new FreeSmartphone.GSM.Error.SIM_AUTH_FAILED( @"ISI Code = $isicode" );
                break;
        }
    }
}

public class IsiSimGetAuthCodeRequired : SimGetAuthCodeRequired
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        bool required = true;
        bool ok = false;

        NokiaIsi.isimodem.simauth.queryStatus( ( err, code ) => {
            if ( err == ErrorCode.OK )
            {
                if ( code == GIsiClient.SIMAuth.StatusResponseRunningType.UNPROTECTED )
                {
                    required = false;
                }
                ok = true;
            }
            run.callback();
        } );
        yield;

        if ( !ok )
        {
            throw new FreeSmartphone.GSM.Error.DEVICE_FAILED( "Unkown ISI Error");
        }
    }
}

public class IsiSimChangeAuthCode : SimChangeAuthCode
{
    public override async void run( string oldpin, string newpin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        bool ok = true;

        NokiaIsi.isimodem.simauth.changePin( oldpin, newpin, ( err ) => {
            if ( err != ErrorCode.OK )
            {
                ok = false;
            }
            run.callback();
        } );
        yield;

        if ( !ok )
        {
            throw new FreeSmartphone.GSM.Error.DEVICE_FAILED( "Unkown ISI Error");
        }
    }
}

#if 0
public class IsiSimDeleteEntry : SimDeleteEntry
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error 
    {
    }
}

public class IsiSimDeleteMessage : SimDeleteMessage
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error 
    {
    }
}

public class IsiSimGetPhonebookInfo : SimGetPhonebookInfo
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error 
    {
    }
}

public class IsiSimGetServiceCenterNumber : SimGetServiceCenterNumber
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }
}

public class IsiSimGetUnlockCounters : SimGetUnlockCounters
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
//Definition for struct SIM_PIN_ATTEMPTS_LEFT_RESP

    }
}

public class IsiSimRetrievePhonebook : SimRetrievePhonebook
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }
}

public class IsiSimRetrieveMessage : SimRetrieveMessage
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }
}

public class IsiSimSendStoredMessage : SimSendStoredMessage
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }
}

public class IsiSimSetAuthCodeRequired : SimSetAuthCodeRequired
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }
}

public class IsiSimSetServiceCenterNumber : SimSetServiceCenterNumber
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }
}

public class IsiSimStoreMessage : SimStoreMessage
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }
}

public class IsiSimWriteEntry : SimWriteEntry
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }
}

public class IsiSimUnlock : SimUnlock
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }
}
#endif

} // namspace NokiaIsi

// vim:ts=4:sw=4:expandtab
