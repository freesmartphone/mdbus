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

/**
 * Mediator Interfaces and Base Class
 **/

public abstract interface FsoGsm.Mediator
{
}

public abstract class FsoGsm.AbstractMediator : FsoGsm.Mediator, GLib.Object
{
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
    public GLib.HashTable<string,GLib.Value?> features { get; set; }
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
    public GLib.HashTable<string,GLib.Value?> info { get; set; }
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
    public GLib.HashTable<string,Value?> info { get; set; }
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

public abstract class FsoGsm.SimRetrievePhonebook : FsoGsm.AbstractMediator
{
    public FreeSmartphone.GSM.SIMEntry[] phonebook { get; set; }
    public abstract async void run( string category, int mindex, int maxdex ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.SimRetrieveMessagebook : FsoGsm.AbstractMediator
{
    public FreeSmartphone.GSM.SIMMessage[] messagebook { get; set; }
    public abstract async void run( string category ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.SimSendAuthCode : FsoGsm.AbstractMediator
{
    public abstract async void run( string pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.SimSetAuthCodeRequired : FsoGsm.AbstractMediator
{
    public abstract async void run( bool required, string pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.SimSetServiceCenterNumber : FsoGsm.AbstractMediator
{
    public abstract async void run( string number ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
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
    public GLib.HashTable<string,GLib.Value?> status { get; set; }
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

public abstract class FsoGsm.NetworkUnregister : FsoGsm.AbstractMediator
{
    public abstract async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
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

//
// org.freesmartphone.GSM.Pdp.*
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
