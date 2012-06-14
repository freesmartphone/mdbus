/*
 * Copyright (C) 2011 Klaus 'mrmoku' Kurzmann <mok@fluxnetz.de>
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
 **/

using Gee;
using FsoGsm;

namespace NokiaIsi
{

/*
 * Register Mediators
 */
static void registerMediators( HashMap<Type,Type> mediators )
{
    mediators[ typeof(DeviceGetInformation) ]            = typeof( IsiDeviceGetInformation );
    mediators[ typeof(DeviceSetFunctionality) ]          = typeof( IsiDeviceSetFunctionality );

    mediators[ typeof(SimGetAuthStatus) ]                = typeof( IsiSimGetAuthStatus );
    mediators[ typeof(SimGetInformation) ]               = typeof( IsiSimGetInformation );
    mediators[ typeof(SimSendAuthCode) ]                 = typeof( IsiSimSendAuthCode );
    mediators[ typeof(SimGetAuthCodeRequired) ]          = typeof( IsiSimGetAuthCodeRequired );
    mediators[ typeof(SimChangeAuthCode) ]               = typeof( IsiSimChangeAuthCode );

    mediators[ typeof(NetworkGetStatus) ]                = typeof( IsiNetworkGetStatus );
    mediators[ typeof(NetworkGetSignalStrength) ]        = typeof( IsiNetworkGetSignalStrength );
    mediators[ typeof(NetworkListProviders) ]            = typeof( IsiNetworkListProviders );
    mediators[ typeof(NetworkRegister) ]                 = typeof( IsiNetworkRegister );
    mediators[ typeof(NetworkRegisterWithProvider) ]     = typeof( IsiNetworkRegisterWithProvider );

    mediators[ typeof(CallActivate) ]                    = typeof( IsiCallActivate );
    mediators[ typeof(CallHoldActive) ]                  = typeof( IsiCallHoldActive );
    mediators[ typeof(CallInitiate) ]                    = typeof( IsiCallInitiate );
    mediators[ typeof(CallRelease) ]                     = typeof( IsiCallRelease );
    mediators[ typeof(CallReleaseAll) ]                  = typeof( IsiCallReleaseAll );
    mediators[ typeof(CallListCalls) ]                   = typeof( IsiCallListCalls );
    mediators[ typeof(CallSendDtmf) ]                    = typeof( IsiCallSendDtmf );

    mediators[ typeof(PdpGetCredentials) ]               = typeof( AtPdpGetCredentials );
    mediators[ typeof(PdpSetCredentials) ]               = typeof( IsiPdpSetCredentials );
    mediators[ typeof(PdpActivateContext) ]              = typeof( AtPdpActivateContext ); 
    mediators[ typeof(PdpDeactivateContext) ]            = typeof( AtPdpDeactivateContext ); 

    mediators[ typeof(DebugCommand) ]                    = typeof( IsiDebugCommand );

    modem.logger.debug( "Nokia ISI mediators registered" );
}

public async void triggerUpdateNetworkStatus() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
{
    //NokiaIsi.isimodem.net
}


public async void gatherSimStatusAndUpdate() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
{
    //NokiaIsi.isimodem.simauth.queryStatus( ( err, res ) => {
    //    curstate = 
}

} // namespace NokiaIsi

// vim:ts=4:sw=4:expandtab
