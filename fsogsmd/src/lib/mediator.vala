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

using FsoGsm.Constants;

/**
 * Mediator Interfaces and Base Class
 **/

public interface FsoGsm.Mediator : GLib.Object
{
    public abstract void assign_modem( FsoGsm.Modem modem );
}

public abstract class FsoGsm.AbstractMediator : FsoGsm.Mediator, GLib.Object
{
    protected FsoGsm.Modem modem { get; private set; }

    public void assign_modem( FsoGsm.Modem modem )
    {
        this.modem = modem;
    }
}

//
// org.freesmartphone.GSM.Debug.*
//
public abstract class FsoGsm.DebugCommand : FsoGsm.AbstractMediator
{
    public string response { get; set; }
    public abstract async void run( string command, string channel ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.DebugInjectResponse : FsoGsm.AbstractMediator
{
    public abstract async void run( string command, string channel ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.DebugPing : FsoGsm.AbstractMediator
{
    public abstract async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

//
// org.freesmartphone.GSM.Device.*
//
public abstract class FsoGsm.DeviceGetAlarmTime : FsoGsm.AbstractMediator
{
    public int since_epoch { get; set; }
    public abstract async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.DeviceGetCurrentTime : FsoGsm.AbstractMediator
{
    public int since_epoch { get; set; }
    public abstract async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.DeviceGetFeatures : FsoGsm.AbstractMediator
{
    public GLib.HashTable<string,GLib.Variant> features { get; set; }
    public abstract async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.DeviceGetFunctionality : FsoGsm.AbstractMediator
{
    public string level { get; set; }
    public bool autoregister { get; set; }
    public string pin { get; set; }
    public abstract async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.DeviceGetInformation : FsoGsm.AbstractMediator
{
    public GLib.HashTable<string,GLib.Variant> info { get; set; }
    public abstract async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.DeviceGetMicrophoneMuted : FsoGsm.AbstractMediator
{
    public bool muted { get; set; }
    public abstract async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.DeviceGetPowerStatus : FsoGsm.AbstractMediator
{
    public FreeSmartphone.Device.PowerStatus status { get; set; }
    public int level { get; set; }
    public abstract async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.DeviceGetSimBuffersSms : FsoGsm.AbstractMediator
{
    public bool buffers { get; set; }
    public abstract async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.DeviceGetSpeakerVolume : FsoGsm.AbstractMediator
{
    public int volume { get; set; }
    public abstract async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.DeviceSetAlarmTime : FsoGsm.AbstractMediator
{
    public abstract async void run( int since_epoch ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.DeviceSetCurrentTime : FsoGsm.AbstractMediator
{
    public abstract async void run( int since_epoch ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.DeviceSetFunctionality : FsoGsm.AbstractMediator
{
    public abstract async void run( string level, bool autoregister, string pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.DeviceSetMicrophoneMuted : FsoGsm.AbstractMediator
{
    public abstract async void run( bool muted ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.DeviceSetSpeakerVolume : FsoGsm.AbstractMediator
{
    public abstract async void run( int volume ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

//
// org.freesmartphone.GSM.SIM.*
//
public abstract class FsoGsm.SimChangeAuthCode : FsoGsm.AbstractMediator
{
    public abstract async void run( string oldpin, string newpin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.SimDeleteEntry : FsoGsm.AbstractMediator
{
    public abstract async void run( string category, int index ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.SimDeleteMessage : FsoGsm.AbstractMediator
{
    public abstract async void run( int index ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.SimGetAuthCodeRequired : FsoGsm.AbstractMediator
{
    public bool required;
    public abstract async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.SimGetAuthStatus : FsoGsm.AbstractMediator
{
    public FreeSmartphone.GSM.SIMAuthStatus status;
    public abstract async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.SimGetInformation : FsoGsm.AbstractMediator
{
    public GLib.HashTable<string,Variant> info { get; set; }
    public abstract async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.SimGetPhonebookInfo : FsoGsm.AbstractMediator
{
    public abstract async void run( string category, out int slots, out int numberlength, out int namelength ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.SimGetServiceCenterNumber : FsoGsm.AbstractMediator
{
    public string number;
    public abstract async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.SimGetUnlockCounters : FsoGsm.AbstractMediator
{
    public GLib.HashTable<string,Variant> counters { get; set; }
    public abstract async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.SimRetrievePhonebook : FsoGsm.AbstractMediator
{
    public FreeSmartphone.GSM.SIMEntry[] phonebook { get; set; }
    public abstract async void run( string category, int mindex, int maxdex ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.SimRetrieveMessage : FsoGsm.AbstractMediator
{
    public abstract async void run( int index, out string status, out string number, out string contents, out GLib.HashTable<string,GLib.Variant> properties ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.SimSendAuthCode : FsoGsm.AbstractMediator
{
    public abstract async void run( string pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.SimSendStoredMessage : FsoGsm.AbstractMediator
{
    public int transaction_index { get; set; }
    public string timestamp { get; set; }
    public abstract async void run( int index ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.SimSetAuthCodeRequired : FsoGsm.AbstractMediator
{
    public abstract async void run( bool required, string pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.SimSetServiceCenterNumber : FsoGsm.AbstractMediator
{
    public abstract async void run( string number ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.SimStoreMessage : FsoGsm.AbstractMediator
{
    public int memory_index { get; set; }
    public abstract async void run( string recipient_number, string contents, bool want_report ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.SimWriteEntry : FsoGsm.AbstractMediator
{
    public abstract async void run( string category, int index, string number, string name ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.SimUnlock : FsoGsm.AbstractMediator
{
    public abstract async void run( string puk, string newpin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

//
// org.freesmartphone.GSM.SMS.*
//
public abstract class FsoGsm.SmsRetrieveTextMessages : FsoGsm.AbstractMediator
{
    public FreeSmartphone.GSM.SIMMessage[] messagebook { get; set; }
    public abstract async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.SmsGetSizeForTextMessage : FsoGsm.AbstractMediator
{
    public uint size { get; set; }
    public abstract async void run( string contents ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.SmsSendTextMessage : FsoGsm.AbstractMediator
{
    public int transaction_index { get; set; }
    public string timestamp { get; set; }
    public abstract async void run( string recipient_number, string contents, bool want_report ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

//
// org.freesmartphone.GSM.Network.*
//
public abstract class FsoGsm.NetworkGetSignalStrength : FsoGsm.AbstractMediator
{
    public int signal { get; set; }
    public abstract async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.NetworkGetStatus : FsoGsm.AbstractMediator
{
    public GLib.HashTable<string,GLib.Variant> status { get; set; }
    public abstract async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.NetworkListProviders : FsoGsm.AbstractMediator
{
    public FreeSmartphone.GSM.NetworkProvider[] providers { get; set; }
    public abstract async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.NetworkRegister : FsoGsm.AbstractMediator
{
    public abstract async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.NetworkRegisterWithProvider : FsoGsm.AbstractMediator
{
    public abstract async void run( string provider ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.NetworkSendUssdRequest : FsoGsm.AbstractMediator
{
    public abstract async void run( string request ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.NetworkUnregister : FsoGsm.AbstractMediator
{
    public abstract async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.NetworkGetCallingId : FsoGsm.AbstractMediator
{
    public FreeSmartphone.GSM.CallingIdentificationStatus status { get; set; }
    public abstract async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.NetworkSetCallingId : FsoGsm.AbstractMediator
{
    public abstract async void run( FreeSmartphone.GSM.CallingIdentificationStatus status ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

//
// org.freesmartphone.GSM.Call.*
//
public abstract class FsoGsm.CallActivate : FsoGsm.AbstractMediator
{
    public abstract async void run( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.CallHoldActive : FsoGsm.AbstractMediator
{
    public abstract async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.CallInitiate : FsoGsm.AbstractMediator
{
    public int id { get; set; }
    public abstract async void run( string number, string typ ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.CallListCalls : FsoGsm.AbstractMediator
{
    public FreeSmartphone.GSM.CallDetail[] calls { get; set; }
    public abstract async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.CallRelease : FsoGsm.AbstractMediator
{
    public abstract async void run( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.CallReleaseAll : FsoGsm.AbstractMediator
{
    public abstract async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.CallSendDtmf : FsoGsm.AbstractMediator
{
    public abstract async void run( string tones ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.CallTransfer : FsoGsm.AbstractMediator
{
    public abstract async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.CallDeflect : FsoGsm.AbstractMediator
{
    public abstract async void run( string number ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.CallJoin : FsoGsm.AbstractMediator
{
    public abstract async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.CallActivateConference : FsoGsm.AbstractMediator
{
    public abstract async void run( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

//
// org.freesmartphone.GSM.CallForwarding.*
//

public abstract class FsoGsm.CallForwardingEnable : FsoGsm.AbstractMediator
{
    public abstract async void run( BearerClass cls, CallForwardingType reason, string number, int time ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.CallForwardingDisable : FsoGsm.AbstractMediator
{
    public abstract async void run( BearerClass cls, CallForwardingType reason ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.CallForwardingQuery : FsoGsm.AbstractMediator
{
    public GLib.HashTable<string,Variant> status { get; protected set; }

    public abstract async void run( BearerClass cls, CallForwardingType reason ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

//
// org.freesmartphone.GSM.PDP.*
//
public abstract class FsoGsm.PdpActivateContext : FsoGsm.AbstractMediator
{
    public abstract async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.PdpDeactivateContext : FsoGsm.AbstractMediator
{
    public abstract async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.PdpSetCredentials : FsoGsm.AbstractMediator
{
    public abstract async void run( string apn, string username, string password ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.PdpGetCredentials : FsoGsm.AbstractMediator
{
    public string apn { get; set; }
    public string username { get; set; }
    public string password { get; set; }
    public abstract async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

//
// org.freesmartphone.GSM.CB.*
//
public abstract class FsoGsm.CbSetCellBroadcastSubscriptions : FsoGsm.AbstractMediator
{
    public abstract async void run( string subscriptions ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.CbGetCellBroadcastSubscriptions : FsoGsm.AbstractMediator
{
    public string subscriptions { get; set; }

    public abstract async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

//
// org.freesmartphone.GSM.Monitor.*
//
public abstract class FsoGsm.MonitorGetServingCellInformation : FsoGsm.AbstractMediator
{
    public GLib.HashTable<string,GLib.Variant> cell { get; set; }

    public abstract async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.MonitorGetNeighbourCellInformation : FsoGsm.AbstractMediator
{
    public GLib.HashTable<string,GLib.Variant>[] cells { get; set; }

    public abstract async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

//
// org.freesmartphone.GSM.VoiceMail.*
//
public abstract class FsoGsm.VoiceMailboxGetNumber : FsoGsm.AbstractMediator
{
    public string number;

    public abstract async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.VoiceMailboxSetNumber : FsoGsm.AbstractMediator
{
    public abstract async void run( string number ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

// vim:ts=4:sw=4:expandtab
