/**
 * Copyright (C) 2009 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

// temp. workaround until Vala's dbus string marshalling via enums is fixed
[DBus (name = "org.freesmartphone.GSM.Call")]
public abstract interface XFreeSmartphone.GSM.Call : GLib.Object {
    public abstract async void activate (int id) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error;
    public abstract async void activate_conference (int id) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error;
    public abstract async void emergency (string number) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error;
    public abstract async void hold_active () throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error;
    public abstract async int initiate (string number, string type) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error;
    public abstract async void join () throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error;
    public abstract async XFreeSmartphone.GSM.CallDetail[] list_calls () throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error;
    public abstract async void release (int id) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error;
    public abstract async void release_all () throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error;
    public abstract async void release_held () throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error;
    public abstract async void send_dtmf (string tones) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error;
    public abstract async void transfer (string number) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error;
    public signal void call_status (int id, string status, GLib.HashTable<string,GLib.Value?> properties);
}


/**
 * Mediator Interfaces and Base Class
 **/

public abstract interface FsoGsm.Mediator
{
    protected void checkResponseOk( FsoGsm.AtCommand command, string[] response ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var code = command.validateOk( response );
        if ( code == Constants.AtResponse.OK )
        {
            return;
        }

        //FIXME: gather better error message out of response status
        throw new FreeSmartphone.GSM.Error.DEVICE_FAILED( response[response.length-1] );
    }

    protected void checkTestResponseValid( FsoGsm.AtCommand command, string[] response ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var code = command.validateTest( response );
        if ( code == Constants.AtResponse.VALID )
        {
            return;
        }

        //FIXME: gather better error message out of response status
        throw new FreeSmartphone.GSM.Error.DEVICE_FAILED( "Unexpected AT command response" );
    }

    protected void checkResponseValid( FsoGsm.AtCommand command, string[] response ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var code = command.validate( response );
        if ( code == Constants.AtResponse.VALID )
        {
            return;
        }

        //FIXME: gather better error message out of response status
        throw new FreeSmartphone.GSM.Error.DEVICE_FAILED( "Unexpected AT command response" );
    }

    protected void checkMultiResponseValid( FsoGsm.AtCommand command, string[] response ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var code = command.validateMulti( response );
        if ( code == Constants.AtResponse.VALID )
        {
            return;
        }

        //FIXME: gather better error message out of response status
        throw new FreeSmartphone.GSM.Error.DEVICE_FAILED( "Unexpected AT command response" );
    }
}

public abstract class FsoGsm.AbstractMediator : FsoGsm.Mediator, GLib.Object
{
}

//
// org.freesmartphone.GSM.Device.*
//
public abstract class FsoGsm.DeviceGetAlarmTime : FsoGsm.AbstractMediator
{
    public int since_epoch { get; set; }
    public abstract async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.DeviceGetAntennaPower : FsoGsm.AbstractMediator
{
    public bool antenna_power { get; set; }
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
    public string status { get; set; }
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
    public abstract async void run( string level ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.DeviceSetMicrophoneMuted : FsoGsm.AbstractMediator
{
    public abstract async void run( bool muted ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.DeviceSetSimBuffersSms : FsoGsm.AbstractMediator
{
    public abstract async void run( bool buffers ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
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

public abstract class FsoGsm.SimGetServiceCenterNumber : FsoGsm.AbstractMediator
{
    public string number;
    public abstract async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.SimListPhonebooks : FsoGsm.AbstractMediator
{
    public string[] phonebooks { get; set; }
    public abstract async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.SimRetrievePhonebook : FsoGsm.AbstractMediator
{
    public FreeSmartphone.GSM.SIMEntry[] phonebook { get; set; }
    public abstract async void run( string category ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
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

public abstract class FsoGsm.SimSetServiceCenterNumber : FsoGsm.AbstractMediator
{
    public abstract async void run( string number ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public abstract class FsoGsm.SimUnlock : FsoGsm.AbstractMediator
{
    public abstract async void run( string puk, string newpin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
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

// work around since string marshalling seems somewhat broken atm.
public struct XFreeSmartphone.GSM.CallDetail
{
    public int id;
    public string status;
    public GLib.HashTable<string,GLib.Value?> properties;
}

public abstract class FsoGsm.CallListCalls : FsoGsm.AbstractMediator
{
    public XFreeSmartphone.GSM.CallDetail[] calls { get; set; }
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
