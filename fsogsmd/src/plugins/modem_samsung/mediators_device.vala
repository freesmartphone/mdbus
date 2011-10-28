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
        autoregister = theModem.data().keepRegistration;
        pin = theModem.data().simPin;
    }
}

public class SamsungDeviceGetFeatures : DeviceGetFeatures
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        features = new GLib.HashTable<string,Variant>( str_hash, str_equal );

        // Prefill results with what the modem claims
        var data = theModem.data();
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
        var channel = theModem.channel( "main" ) as Samsung.IpcChannel;

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
        }
    }
}

public class SamsungDeviceGetPowerStatus : DeviceGetPowerStatus
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var channel = theModem.channel( "main" ) as Samsung.IpcChannel;

        // FIXME how do we retrieve the current power state from the modem?
        status = FreeSmartphone.Device.PowerStatus.UNKNOWN;
    }
}

public class SamsungDeviceSetFunctionality : DeviceSetFunctionality
{
    public override async void run( string level, bool autoregister, string pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        switch ( level )
        {
            case "minimal":
            case "full":
                var mreg = theModem.createMediator<FsoGsm.NetworkRegister>();
                yield mreg.run();
                break;
            case "airplane":
                var munreg = theModem.createMediator<FsoGsm.NetworkUnregister>();
                yield munreg.run();
                break;
            default:
                throw new FreeSmartphone.Error.INVALID_PARAMETER( "Functionality needs to be one of \"minimal\", \"airplane\", or \"full\"." );
        }
    }
}

// vim:ts=4:sw=4:expandtab
