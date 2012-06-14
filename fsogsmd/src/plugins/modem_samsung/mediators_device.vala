/*
 * Copyright (C) 2011 Simon Busch <morphis@gravedo.de>
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
using FsoFramework;

public class SamsungDeviceGetFunctionality : DeviceGetFunctionality
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        level = gatherFunctionalityLevel();
        autoregister = modem.data().keepRegistration;
        pin = modem.data().simPin;
    }
}

public class SamsungDeviceGetFeatures : DeviceGetFeatures
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        features = new GLib.HashTable<string,Variant>( str_hash, str_equal );

        // Prefill results with what the modem claims
        var data = modem.data();
        features.insert( "gsm", data.supportsGSM );
        features.insert( "voice", data.supportsVoice );
        features.insert( "cdma", data.supportsCDMA );
        features.insert( "csd", data.supportsCSD );
        features.insert( "fax", data.supportsFAX );
        features.insert( "pdp", data.supportsPDP );
    }
}

public class SamsungDeviceGetInformation : DeviceGetInformation
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        unowned SamsungIpc.Response? response = null;
        var channel = modem.channel( "main" ) as Samsung.IpcChannel;

        info = new GLib.HashTable<string,Variant>( str_hash, str_equal );

        info.insert( "model", "Samsung Nexus S" );
        info.insert( "manufacturer", "Samsung" );

        // Retrieve hardware and software version from baseband
        response = yield channel.enqueue_async( SamsungIpc.RequestType.GET, SamsungIpc.MessageType.MISC_ME_VERSION,
                                                new uint8[] { 0xff } );
        if ( response != null )
        {
            var message = (SamsungIpc.Misc.VersionMessage*) (response.data);

            assert( theLogger.debug( @"Baseband software version info:" ) );
            assert( theLogger.debug( @" sw_version = $((string) message.sw_version), hw_version = $((string) message.hw_version)" ) );
            assert( theLogger.debug( @" cal_date = $((string) message.cal_date)") );
            assert( theLogger.debug( @" misc = $((string) message.misc)") );

            info.insert( "sw-version", (string) message.sw_version );
            info.insert( "hw-version", (string) message.hw_version );
            info.insert( "cal-date", (string) message.cal_date );
            info.insert( "misc", (string) message.misc );
        }
    }
}

public class SamsungDeviceGetPowerStatus : DeviceGetPowerStatus
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var channel = modem.channel( "main" ) as Samsung.IpcChannel;
        status = FreeSmartphone.Device.PowerStatus.UNKNOWN;
    }
}

public class SamsungDeviceSetFunctionality : DeviceSetFunctionality
{
    public override async void run( string level, bool autoregister, string pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var channel = modem.channel( "main" ) as Samsung.IpcChannel;

        switch ( level )
        {
            case "minimal":
                // FIXME we current not supporting any mode that sets the modem into a
                // minimal state were SIM access is not possible. We can't do this
                // with the current version of the IPC protocol (as far as we know).
                throw new FreeSmartphone.Error.UNSUPPORTED( "Setting functionality to minimal is not supported" );
            case "airplane":
                channel.update_modem_power_state( SamsungIpc.Power.PhoneState.LPM );
                break;
            case "full":
                channel.update_modem_power_state( SamsungIpc.Power.PhoneState.NORMAL );
                break;
            default:
                throw new FreeSmartphone.Error.INVALID_PARAMETER( "Functionality needs to be one of \"minimal\", \"airplane\", or \"full\"." );
        }

        var data = modem.data();
        data.keepRegistration = autoregister;
        if ( pin != "" )
        {
            data.simPin = pin;
            modem.watchdog.resetUnlockMarker();
        }
    }
}

// vim:ts=4:sw=4:expandtab
