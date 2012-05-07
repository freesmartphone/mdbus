/*
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *                         Simon Busch <morphis@gravedo.de>
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

/**
 * Register all mediators
 **/
public void registerMsmMediators( HashMap<Type,Type> table )
{
    table[ typeof(DebugCommand) ]                 = typeof( MsmDebugCommand );
    table[ typeof(DebugInjectResponse) ]          = typeof( MsmDebugInjectResponse );
    table[ typeof(DebugPing) ]                    = typeof( MsmDebugPing );

    table[ typeof(SimGetAuthCodeRequired) ]       = typeof( MsmSimGetAuthCodeRequired );
    table[ typeof(SimGetAuthStatus) ]             = typeof( MsmSimGetAuthStatus );
    table[ typeof(SimSendAuthCode) ]              = typeof( MsmSimSendAuthCode );
    table[ typeof(SimGetInformation) ]            = typeof( MsmSimGetInformation );
    table[ typeof(SimDeleteEntry) ]               = typeof( MsmSimDeleteEntry );
    table[ typeof(SimGetPhonebookInfo) ]          = typeof( MsmSimGetPhonebookInfo );
    table[ typeof(SimWriteEntry) ]                = typeof( MsmSimWriteEntry );
    table[ typeof(SimRetrievePhonebook) ]         = typeof( MsmSimRetrievePhonebook );
    table[ typeof(SimWriteEntry) ]                = typeof( MsmSimWriteEntry );
    table[ typeof(SimDeleteMessage) ]             = typeof( MsmSimDeleteMessage );
    table[ typeof(SimGetServiceCenterNumber) ]    = typeof( MsmSimGetServiceCenterNumber );
    table[ typeof(SimGetUnlockCounters) ]         = typeof( MsmSimGetUnlockCounters );
    table[ typeof(SimRetrieveMessage) ]           = typeof( MsmSimRetrieveMessage );
    table[ typeof(SimSendStoredMessage) ]         = typeof( MsmSimSendStoredMessage );
    table[ typeof(SimSetServiceCenterNumber) ]    = typeof( MsmSimSetServiceCenterNumber );
    table[ typeof(SimStoreMessage) ]              = typeof( MsmSimStoreMessage );
    table[ typeof(SimUnlock) ]                    = typeof( MsmSimUnlock );
    table[ typeof(SimChangeAuthCode) ]            = typeof( MsmSimChangeAuthCode );

    table[ typeof(DeviceGetFeatures) ]            = typeof( MsmDeviceGetFeatures );
    table[ typeof(DeviceGetInformation) ]         = typeof( MsmDeviceGetInformation );
    table[ typeof(DeviceGetFunctionality) ]       = typeof( MsmDeviceGetFunctionality );
    table[ typeof(DeviceGetPowerStatus) ]         = typeof( MsmDeviceGetPowerStatus );
    table[ typeof(DeviceSetFunctionality) ]       = typeof( MsmDeviceSetFunctionality );
    table[ typeof(DeviceGetCurrentTime) ]         = typeof( MsmDeviceGetCurrentTime );
    table[ typeof(DeviceSetCurrentTime) ]         = typeof( MsmDeviceSetCurrentTime );
    table[ typeof(DeviceGetAlarmTime) ]           = typeof( MsmDeviceGetAlarmTime );
    table[ typeof(DeviceGetMicrophoneMuted) ]     = typeof( MsmDeviceGetMicrophoneMuted );
    table[ typeof(DeviceGetSimBuffersSms) ]       = typeof( MsmDeviceGetSimBuffersSms );
    table[ typeof(DeviceGetSpeakerVolume) ]       = typeof( MsmDeviceGetSpeakerVolume );
    table[ typeof(DeviceSetAlarmTime) ]           = typeof( MsmDeviceSetAlarmTime );
    table[ typeof(DeviceSetMicrophoneMuted) ]     = typeof( MsmDeviceSetMicrophoneMuted );
    table[ typeof(DeviceSetSpeakerVolume) ]       = typeof( MsmDeviceSetSpeakerVolume );

    table[ typeof(NetworkRegister) ]              = typeof( MsmNetworkRegister );
    table[ typeof(NetworkUnregister) ]            = typeof( MsmNetworkUnregister );
    table[ typeof(NetworkGetStatus) ]             = typeof( MsmNetworkGetStatus );
    table[ typeof(NetworkGetSignalStrength) ]     = typeof( MsmNetworkGetSignalStrength );
    table[ typeof(NetworkListProviders) ]         = typeof( MsmNetworkListProviders );
    table[ typeof(NetworkSetCallingId) ]          = typeof( MsmNetworkSetCallingId );
    table[ typeof(NetworkGetCallingId) ]          = typeof( MsmNetworkGetCallingId );
    table[ typeof(NetworkSendUssdRequest) ]       = typeof( MsmNetworkSendUssdRequest );

    table[ typeof(CallActivate) ]                 = typeof( MsmCallActivate );
    table[ typeof(CallHoldActive) ]               = typeof( MsmCallHoldActive );
    table[ typeof(CallInitiate) ]                 = typeof( MsmCallInitiate );
    table[ typeof(CallListCalls) ]                = typeof( MsmCallListCalls );
    table[ typeof(CallReleaseAll) ]               = typeof( MsmCallReleaseAll );
    table[ typeof(CallRelease) ]                  = typeof( MsmCallRelease );
    table[ typeof(CallSendDtmf) ]                 = typeof( MsmCallSendDtmf );

    table[ typeof(SmsRetrieveTextMessages) ]      = typeof( MsmSmsRetrieveTextMessages );
    table[ typeof(SmsSendTextMessage) ]           = typeof( MsmSmsSendTextMessage );

    table[ typeof(CbSetCellBroadcastSubscriptions) ] = typeof( MsmCbSetCellBroadcastSubscriptions );
    table[ typeof(CbGetCellBroadcastSubscriptions) ] = typeof( MsmCbGetCellBroadcastSubscriptions );

    table[ typeof(MonitorGetServingCellInformation) ] = typeof( MsmMonitorGetServingCellInformation );
    table[ typeof(MonitorGetNeighbourCellInformation) ] = typeof( MsmMonitorGetNeighbourCellInformation );

    table[ typeof(VoiceMailboxGetNumber) ]        = typeof( MsmVoiceMailboxGetNumber );
    table[ typeof(VoiceMailboxSetNumber) ]        = typeof( MsmVoiceMailboxSetNumber );

    //table[ typeof(PdpActivateContext) ]           = typeof( MsmPdpActivateContext );
    //table[ typeof(PdpDeactivateContext) ]         = typeof( MsmPdpDeactivateContext );
    table[ typeof(PdpSetCredentials) ]            = typeof( MsmPdpSetCredentials );
    table[ typeof(PdpGetCredentials) ]            = typeof( MsmPdpGetCredentials );
}

// vim:ts=4:sw=4:expandtab
