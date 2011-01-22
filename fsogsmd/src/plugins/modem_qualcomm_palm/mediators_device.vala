/*
 * Copyright (C) 2010-2011 Simon Busch <morphis@gravedo.de>
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
using Msmcomm;

public class MsmDeviceGetFunctionality : DeviceGetFunctionality
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        level = gatherFunctionalityLevel();
        autoregister = theModem.data().keepRegistration;
        pin = theModem.data().simPin;
    }
}

public class MsmDeviceGetFeatures : DeviceGetFeatures
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

public class MsmDeviceGetInformation : DeviceGetInformation
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var channel = theModem.channel( "main" ) as MsmChannel;

        try
        {
            info = new GLib.HashTable<string,Variant>( str_hash, str_equal );

            info.insert( "model", "Palm Pre/Pre Plus/Pre 2" );
            info.insert( "manufacturer", "Palm, Inc." );

            Msmcomm.RadioFirmwareVersionInfo firmware_info;
            firmware_info = yield channel.misc_service.get_radio_firmware_version();

            info.insert( "revision", firmware_info.firmware_version );
            info.insert( "carrier-id", firmware_info.carrier_id );

            string imei = yield channel.misc_service.get_imei();
            info.insert( "imei", imei );
        }
        catch ( Msmcomm.Error err0 )
        {
            var msg = @"Could not process get_radio_firmware_version or get_imei command, got: $(err0.message)";
            throw new FreeSmartphone.Error.INTERNAL_ERROR( msg );
        }
        catch ( GLib.Error err1 )
        {
        }
    }
}

public class MsmDeviceGetPowerStatus : DeviceGetPowerStatus
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var channel = theModem.channel( "main" ) as MsmChannel;

        try
        {
            Msmcomm.ChargerStatusInfo charger_info = yield channel.misc_service.get_charger_status();

            switch (charger_info.mode)
            {
                case Msmcomm.ChargerMode.USB:
                    status = FreeSmartphone.Device.PowerStatus.AC;
                    break;
                case Msmcomm.ChargerMode.INDUCTIVE:
                    status = FreeSmartphone.Device.PowerStatus.CHARGING;
                    break;
                default:
                    status = FreeSmartphone.Device.PowerStatus.UNKNOWN;
                    break;
            }

            // FIXME How can we find about current charging level? need
            // to fix this in msmcomm! As long as we don't know how to
            // retrieve the right value, we report a very low level.
            level = 10;
        }
        catch ( Msmcomm.Error err0 )
        {
            var msg = @"Could not process get_charger_status command, got: $(err0.message)";
            throw new FreeSmartphone.Error.INTERNAL_ERROR( msg );
        }
        catch ( GLib.Error err1 )
        {
        }
    }
}

public class MsmDeviceSetFunctionality : DeviceSetFunctionality
{
    public override async void run( string level, bool autoregister, string pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var channel = theModem.channel( "main" ) as MsmChannel;

        switch ( level )
        {
            case "minimal":
            case "full":
                MsmData.operation_mode = OperationMode.ONLINE;
                break;
            case "airplane":
                MsmData.operation_mode = OperationMode.OFFLINE;
                break;
            default:
                throw new FreeSmartphone.Error.INVALID_PARAMETER( "Functionality needs to be one of \"minimal\", \"airplane\", or \"full\"." );
        }

        try 
        {
            yield channel.state_service.change_operation_mode( MsmData.operation_mode ); 
        }
        catch ( Msmcomm.Error err0 )
        {
            var msg = @"Could not process change_operation_mode command, got: $(err0.message)";
            throw new FreeSmartphone.Error.INTERNAL_ERROR( msg );
        }
        catch ( GLib.Error err1 )
        {
        }
    }
}

public class MsmDeviceGetCurrentTime : DeviceGetCurrentTime
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
#if 0
        try
        {
            // Fetch time from modem
        }
        catch ( Msmcomm.Error err0 )
        {
        }
        catch ( GLib.Error err1 )
        {
        }

        // some modems strip the leading zero for one-digit chars, so we have to reassemble it
        var timestr = "%02d/%02d/%02d,%02d:%02d:%02d".printf( cmd.year, cmd.month, cmd.day, cmd.hour, cmd.minute, cmd.second );
        var formatstr = "%y/%m/%d,%H:%M:%S";
        var t = GLib.Time();
        t.strptime( timestr, formatstr );
        since_epoch = (int) Linux.timegm( t );
#endif
    }
}

public class MsmDeviceSetCurrentTime : DeviceSetCurrentTime
{
    public override async void run( int since_epoch ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var channel = theModem.channel( "main" ) as MsmChannel;
        var t = GLib.Time.gm( (time_t) since_epoch );

        try
        {
            var info = DateInfo();
            info.year = t.year + 1900 - 2000;
            info.month = t.month + 1;
            info.day = t.day;
            info.hours = t.hour;
            info.minutes = t.minute;
            info.seconds = t.second;
            info.timezone_offset = 0;
            info.time_source = TimeSource.MANUAL;

            yield channel.misc_service.set_date( info );
        }
        catch ( Msmcomm.Error err0 )
        {
            var msg = @"Could not process set_date command, got: $(err0.message)";
            throw new FreeSmartphone.Error.INTERNAL_ERROR( msg );
        }
        catch ( GLib.Error err1 )
        {
        }
    }
}
