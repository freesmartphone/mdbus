/**
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
 * This file contains Dbus/AT command mediators only using official 3GPP AT commands.
 *
 * Do _not_ add vendor-specific mediators here, instead add them to your modem plugin.
 **/

using Gee;

namespace FsoGsm {

public bool modem_microphoneMuted;
public int modem_speakerVolume;
public string modem_pin;
public bool modem_unlocked;
public bool modem_haspin;
public string modem_scsa;

/**
 * Debug Mediators
 **/
public class DummyAtDebugCommand : DebugCommand
{
    public override async void run( string command, string category ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        this.response = "OK";
    }
}

public class DummyAtDebugInjectResponse : DebugInjectResponse
{
    public override async void run( string command, string category ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }
}

public class DummyAtDebugPing : DebugPing
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }
}

/**
 * Device Mediators
 **/
public class DummyAtDeviceGetAlarmTime : DeviceGetAlarmTime
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        since_epoch = 0;
    }
}

public class DummyAtDeviceGetCurrentTime : DeviceGetCurrentTime
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var t = GLib.Time();
        since_epoch = (int) Linux.timegm( t );
    }
}

public class DummyAtDeviceGetFunctionality : DeviceGetFunctionality
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        level = "full";
        autoregister = theModem.data().keepRegistration;
        pin = theModem.data().simPin;
    }
}

public class DummyAtDeviceGetInformation : DeviceGetInformation
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        info = new GLib.HashTable<string,Value?>( str_hash, str_equal );
        info.insert( "model", "FSO2 Dummy Modem" );
        info.insert( "manufacturer", "freesmartphone.org" );
        info.insert( "revision", "V2" );
        info.insert( "imei", "1234567890123456" );
    }
}

public class DummyAtDeviceGetFeatures : DeviceGetFeatures
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        features = new GLib.HashTable<string,Value?>( str_hash, str_equal );
        features.insert( "gsm", "TA" );
        features.insert( "gprs", "B" );
        features.insert( "fax", "4" );
        features.insert( "facilities", "SM" );
    }
}

public class DummyAtDeviceGetMicrophoneMuted : DeviceGetMicrophoneMuted
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        muted = modem_microphoneMuted;
    }
}

public class DummyAtDeviceGetSpeakerVolume : DeviceGetSpeakerVolume
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        volume = modem_speakerVolume;
    }
}

public class DummyAtDeviceGetPowerStatus : DeviceGetPowerStatus
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        status = "AC";
        level = 100;
    }
}

public class DummyAtDeviceSetAlarmTime : DeviceSetAlarmTime
{
    public override async void run( int since_epoch ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }
}

public class DummyAtDeviceSetCurrentTime : DeviceSetCurrentTime
{
    public override async void run( int since_epoch ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }
}

public class DummyAtDeviceSetFunctionality : DeviceSetFunctionality
{
    public override async void run( string level, bool autoregister, string pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        Timeout.add_seconds( 3, run.callback );
        yield;
        
        if ( modem_pin != pin )
        {
            var simiface = theModem.theDevice<FreeSmartphone.GSM.SIM>();
            simiface.auth_status( FreeSmartphone.GSM.SIMAuthStatus.PIN_REQUIRED );
        }
    }
}

public class DummyAtDeviceSetMicrophoneMuted : DeviceSetMicrophoneMuted
{
    public override async void run( bool muted ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        modem_microphoneMuted = muted;
    }
}

public class DummyAtDeviceSetSpeakerVolume : DeviceSetSpeakerVolume
{
    public override async void run( int volume ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        modem_speakerVolume = volume;
    }
}

/**
 * SIM Mediators
 **/
public class DummyAtSimChangeAuthCode : SimChangeAuthCode
{
    public override async void run( string oldpin, string newpin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        if ( oldpin != modem_pin )
        {
            throw new FreeSmartphone.GSM.Error.SIM_AUTH_FAILED( "Wrong PIN" );
        }
        modem_pin = newpin;
    }
}

public class DummyAtSimGetAuthStatus : SimGetAuthStatus
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        status = modem_unlocked ? FreeSmartphone.GSM.SIMAuthStatus.READY : FreeSmartphone.GSM.SIMAuthStatus.PIN_REQUIRED;
    }
}

public class DummyAtSimGetInformation : SimGetInformation
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        info = new GLib.HashTable<string,Value?>( str_hash, str_equal );
        info.insert( "imsi", "262123456789" );
        info.insert( "issuer", "FSO TELEKOM" );
    }
}

public class DummyAtSimGetAuthCodeRequired : SimGetAuthCodeRequired
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        required = modem_haspin;
    }
}

public class DummyAtSimGetServiceCenterNumber : SimGetServiceCenterNumber
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        number = modem_scsa;
    }
}

public class DummyAtSimListPhonebooks : SimListPhonebooks
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        phonebooks = { "contacts" };
    }
}

public class DummyAtSimRetrievePhonebook : SimRetrievePhonebook
{
    public override async void run( string category ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        if ( ! ( category == "contacts" ) )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Category needs to be one of ..." );
        }

        var pb = new FreeSmartphone.GSM.SIMEntry[] {};
        
        pb += FreeSmartphone.GSM.SIMEntry( 1, "Dr. Mickey Lauer", "+4912345678" );
        pb += FreeSmartphone.GSM.SIMEntry( 2, "Dr. Sabine Lauer", "+4976543210" );
        pb += FreeSmartphone.GSM.SIMEntry( 3, "Daniel Willmann", "+4976543210" );
        pb += FreeSmartphone.GSM.SIMEntry( 4, "Jan Lübbe", "+4976543210" );
        pb += FreeSmartphone.GSM.SIMEntry( 5, "Stefan Schmidt", "+497655543210" );
        pb += FreeSmartphone.GSM.SIMEntry( 6, "Frederik Sdun", "+497651243210" );
        pb += FreeSmartphone.GSM.SIMEntry( 7, "Simon Busch", "+497116543210" );
        pb += FreeSmartphone.GSM.SIMEntry( 8, "Mr. Moku", "+492376543210" );
        pb += FreeSmartphone.GSM.SIMEntry( 9, "Hans Wurst", "+493376543210" );
        pb += FreeSmartphone.GSM.SIMEntry( 10, "Prof. Med. Wurst", "+493376543210" );
        pb += FreeSmartphone.GSM.SIMEntry( 11, "Wer 'auch' immer", "+4971236543210" );
        pb += FreeSmartphone.GSM.SIMEntry( 12, "Sir Lancelot", "+1555543210" );
        pb += FreeSmartphone.GSM.SIMEntry( 13, "Merlin", "+410001w552w455543210" );

        this.phonebook = pb;
    }
}

public class DummyAtSimRetrieveMessagebook : SimRetrieveMessagebook
{
    public override async void run( string category ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var mb = new FreeSmartphone.GSM.SIMMessage[] {};

        var props = new GLib.HashTable<string,GLib.Value?>( GLib.str_hash, GLib.str_equal );

        mb += FreeSmartphone.GSM.SIMMessage( 1, "READ", "+123456789", "Yo, what's up in da house tonight?", props );
        mb += FreeSmartphone.GSM.SIMMessage( 2, "READ", "+555456789", "It's going to be cold, don't forget your coat, sun!", props );
        mb += FreeSmartphone.GSM.SIMMessage( 3, "READ", "+123456789", "And I thought you loved me :(", props );
        mb += FreeSmartphone.GSM.SIMMessage( 4, "READ", "+555456789", "Don't forget to bring Dad's medicine", props );

        this.messagebook = mb;
    }
}

public class DummyAtSimSetAuthCodeRequired : SimSetAuthCodeRequired
{
    public override async void run( bool required, string pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }
}

public class DummyAtSimSendAuthCode : SimSendAuthCode
{
    public override async void run( string pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        if ( pin != modem_pin )
        {
            throw new FreeSmartphone.GSM.Error.SIM_AUTH_FAILED( @"PIN $pin not accepted" );
        }
        theModem.advanceToState( Modem.Status.ALIVE_SIM_UNLOCKED );
    }
}

public class DummyAtSimSetServiceCenterNumber : SimSetServiceCenterNumber
{
    public override async void run( string number ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        modem_scsa = number;
    }
}

public class DummyAtSimUnlock : SimUnlock
{
    public override async void run( string puk, string newpin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        modem_pin = newpin;
    }
}

/**
 * SMS Mediators
 **/
public class DummyAtSmsSendMessage : SmsSendMessage
{
    public override async void run( string recipient_number, string contents, bool want_report ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        transaction_index = 1;
        timestamp = "now";
    }
}

/**
 * Network Mediators
 **/
public class DummyAtNetworkGetSignalStrength : NetworkGetSignalStrength
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        signal = 50;
    }
}

public class DummyAtNetworkGetStatus : NetworkGetStatus
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        status = new GLib.HashTable<string,Value?>( str_hash, str_equal );
        status.insert( "strength", 50 );
        status.insert( "registration", "home" );
        status.insert( "lac", "F71A" );
        status.insert( "cid", "AB12" );

        status.insert( "mode", "home" );
        status.insert( "provider", "FSO TELEKOM" );
        status.insert( "act", "EDGE" );

        status.insert( "code", "262171" );
    }
}

public class DummyAtNetworkListProviders : NetworkListProviders
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        //providers = cmd.providers;
    }
}

public class DummyAtNetworkRegister : NetworkRegister
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        Timeout.add_seconds( 5, run.callback );
        yield;
    }
}

/**
 * Call Mediators
 **/
public class DummyAtCallActivate : CallActivate
{
    public override async void run( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }
}

public class DummyAtCallHoldActive : CallHoldActive
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }
}

public class DummyAtCallInitiate : CallInitiate
{
    public override async void run( string number, string ctype ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }
}

public class DummyAtCallListCalls : CallListCalls
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        //calls = cmd.calls;
    }
}

public class DummyAtCallSendDtmf : CallSendDtmf
{
    public override async void run( string tones ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }
}

public class DummyAtCallRelease : CallRelease
{
    public override async void run( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }
}

public class DummyAtCallReleaseAll : CallReleaseAll
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }
}

public class DummyAtPdpActivateContext : PdpActivateContext
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var data = theModem.data();
        if ( data.contextParams == null )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "No credentials set. Call org.freesmartphone.GSM.PDP.SetCredentials first." );
        }
    }
}

public class DummyAtPdpDeactivateContext : PdpDeactivateContext
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }
}

public class DummyAtPdpGetCredentials : PdpGetCredentials
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var data = theModem.data();
        if ( data.contextParams == null )
        {
            apn = "";
            username = "";
            password = "";
        }
        else
        {
            apn = data.contextParams.apn;
            username = data.contextParams.username;
            password = data.contextParams.password;
        }
    }
}

public class DummyAtPdpSetCredentials : PdpSetCredentials
{
    public override async void run( string apn, string username, string password ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var data = theModem.data();
        data.contextParams = new ContextParams( apn, username, password );
    }
}

/**
 * Register all mediators
 **/
public void registerDummyMediators( HashMap<Type,Type> table )
{
    table[ typeof(DebugCommand) ]                 = typeof( DummyAtDebugCommand );
    table[ typeof(DebugInjectResponse) ]          = typeof( DummyAtDebugInjectResponse );
    table[ typeof(DebugPing) ]                    = typeof( DummyAtDebugPing );

    table[ typeof(DeviceGetAlarmTime) ]           = typeof( DummyAtDeviceGetAlarmTime );
    table[ typeof(DeviceGetCurrentTime) ]         = typeof( DummyAtDeviceGetCurrentTime );
    table[ typeof(DeviceGetInformation) ]         = typeof( DummyAtDeviceGetInformation );
    table[ typeof(DeviceGetFeatures) ]            = typeof( DummyAtDeviceGetFeatures );
    table[ typeof(DeviceGetFunctionality) ]       = typeof( DummyAtDeviceGetFunctionality );
    table[ typeof(DeviceGetMicrophoneMuted) ]     = typeof( DummyAtDeviceGetMicrophoneMuted );
    table[ typeof(DeviceGetPowerStatus) ]         = typeof( DummyAtDeviceGetPowerStatus );
    table[ typeof(DeviceGetSpeakerVolume) ]       = typeof( DummyAtDeviceGetSpeakerVolume );
    table[ typeof(DeviceSetAlarmTime) ]           = typeof( DummyAtDeviceSetAlarmTime );
    table[ typeof(DeviceSetCurrentTime) ]         = typeof( DummyAtDeviceSetCurrentTime );
    table[ typeof(DeviceSetFunctionality) ]       = typeof( DummyAtDeviceSetFunctionality );
    table[ typeof(DeviceSetMicrophoneMuted) ]     = typeof( DummyAtDeviceSetMicrophoneMuted );
    table[ typeof(DeviceSetSpeakerVolume) ]       = typeof( DummyAtDeviceSetSpeakerVolume );

    table[ typeof(SimChangeAuthCode) ]            = typeof( DummyAtSimChangeAuthCode );
    table[ typeof(SimGetAuthCodeRequired) ]       = typeof( DummyAtSimGetAuthCodeRequired );
    table[ typeof(SimGetAuthStatus) ]             = typeof( DummyAtSimGetAuthStatus );
    table[ typeof(SimGetServiceCenterNumber) ]    = typeof( DummyAtSimGetServiceCenterNumber );
    table[ typeof(SimGetInformation) ]            = typeof( DummyAtSimGetInformation );
    table[ typeof(SimListPhonebooks) ]            = typeof( DummyAtSimListPhonebooks );
    table[ typeof(SimRetrieveMessagebook) ]       = typeof( DummyAtSimRetrieveMessagebook );
    table[ typeof(SimRetrievePhonebook) ]         = typeof( DummyAtSimRetrievePhonebook );
    table[ typeof(SimSetAuthCodeRequired) ]       = typeof( DummyAtSimSetAuthCodeRequired );
    table[ typeof(SimSendAuthCode) ]              = typeof( DummyAtSimSendAuthCode );
    table[ typeof(SimSetServiceCenterNumber) ]    = typeof( DummyAtSimSetServiceCenterNumber );
    table[ typeof(SimUnlock) ]                    = typeof( DummyAtSimUnlock );

    table[ typeof(SmsSendMessage) ]               = typeof( DummyAtSmsSendMessage );

    table[ typeof(NetworkGetSignalStrength) ]     = typeof( DummyAtNetworkGetSignalStrength );
    table[ typeof(NetworkGetStatus) ]             = typeof( DummyAtNetworkGetStatus );
    table[ typeof(NetworkListProviders) ]         = typeof( DummyAtNetworkListProviders );
    table[ typeof(NetworkRegister) ]              = typeof( DummyAtNetworkRegister );

    table[ typeof(CallActivate) ]                 = typeof( DummyAtCallActivate );
    table[ typeof(CallHoldActive) ]               = typeof( DummyAtCallHoldActive );
    table[ typeof(CallInitiate) ]                 = typeof( DummyAtCallInitiate );
    table[ typeof(CallListCalls) ]                = typeof( DummyAtCallListCalls );
    table[ typeof(CallReleaseAll) ]               = typeof( DummyAtCallReleaseAll );
    table[ typeof(CallRelease) ]                  = typeof( DummyAtCallRelease );
    table[ typeof(CallSendDtmf) ]                 = typeof( DummyAtCallSendDtmf );

    table[ typeof(PdpActivateContext) ]           = typeof( DummyAtPdpActivateContext );
    table[ typeof(PdpDeactivateContext) ]         = typeof( DummyAtPdpDeactivateContext );
    table[ typeof(PdpSetCredentials) ]            = typeof( DummyAtPdpSetCredentials );
    table[ typeof(PdpGetCredentials) ]            = typeof( DummyAtPdpGetCredentials );

}

} // namespace FsoGsm
