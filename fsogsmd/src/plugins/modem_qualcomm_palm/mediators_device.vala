/*
 * Copyright (C) 2010 Simon Busch <morphis@gravedo.de>
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
 
public class MsmDeviceGetFunctionality : DeviceGetFunctionality
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        // NOTE: We currently cannot get the functionality status directly
        // from the modem, so we have to save it statically and switch it
        // whenever we need
        level = Msmcomm.deviceFunctionalityStatusToString( Msmcomm.RuntimeData.functionality_status );
        
        autoregister = theModem.data().keepRegistration;
        pin = theModem.data().simPin;
    }
}

public class MsmDeviceGetFeatures : DeviceGetFeatures
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        features = new GLib.HashTable<string,Variant>( str_hash, str_equal );
        
        // NOTE there is actually no command to get all the features
        // from the modem itself; in some responses or urcs are some of
        // this information included. We have to gather them while 
        // handling this response and urcs and update the modem data
        // structure accordingly.

        // prefill results with what the modem claims
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
        var cmds = MsmModemAgent.instance().commands;
        
        try
        {
            info = new GLib.HashTable<string,Variant>( str_hash, str_equal );

            info.insert( "model", "Palm Pre (Plus)" );
            info.insert( "manufacturer", "Palm, Inc." );
            
            Msmcomm.FirmwareInfo firmware_info;
            firmware_info = yield cmds.get_firmware_info();
            
            info.insert( "revision", firmware_info.version_string );

            string imei = yield cmds.get_imei();
            info.insert( "imei", imei );
        }
        catch ( Msmcomm.Error err0 )
        {
            var msg = @"Could not process get_firmware_info/get_imei command, got: $(err0.message)";
            throw new FreeSmartphone.Error.INTERNAL_ERROR( msg );
        }
        catch ( DBusError, IOError err1 )
        {
        }
    }
}

public class MsmDeviceGetPowerStatus : DeviceGetPowerStatus
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        try
        {
            var cmds = MsmModemAgent.instance().commands;
            Msmcomm.ChargerStatus charger_status = yield cmds.get_charger_status();
                
            switch (charger_status.mode)
            {
                case Msmcomm.ChargerStatusMode.USB:
                    status = FreeSmartphone.Device.PowerStatus.AC;
                    break;
                case Msmcomm.ChargerStatusMode.INDUCTIVE:
                    status = FreeSmartphone.Device.PowerStatus.CHARGING;
                    break;
                default:                                                
                    status = FreeSmartphone.Device.PowerStatus.UNKNOWN;
                    break;
            }
            
            // FIXME How can we find about current charging level? need
            // to fix this in msmcomm! As long as we don't know how to
            // retrieve the right value, we report a very low level to 
            // indicate that the user should have a charging status very
            // close as current level is unknown ...
            level = 10;
        }
        catch ( Msmcomm.Error err0 )
        {
            var msg = @"Could not process get_charger_status command, got: $(err0.message)";
            throw new FreeSmartphone.Error.INTERNAL_ERROR( msg );
        }
        catch ( DBusError, IOError err1 )
        {
        }
    }
}

public class MsmDeviceSetFunctionality : DeviceSetFunctionality
{
    public override async void run( string level, bool autoregister, string pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var operation_mode = "offline";
        
        switch ( level )
        {
            case "minimal":
            case "full":
                Msmcomm.RuntimeData.functionality_status = Msmcomm.ModemOperationMode.ONLINE;
                break;
            case "airplane":
                Msmcomm.RuntimeData.functionality_status = Msmcomm.ModemOperationMode.OFFLINE;
                break;
            default:
                throw new FreeSmartphone.Error.INVALID_PARAMETER( "Functionality needs to be one of \"minimal\", \"airplane\", or \"full\"." );
        }

        try 
        {
            var cmds = MsmModemAgent.instance().commands;
            yield cmds.change_operation_mode( Msmcomm.RuntimeData.functionality_status ); 
        }
        catch ( Msmcomm.Error err0 )
        {
            var msg = @"Could not process change_operation_mode command, got: $(err0.message)";
            throw new FreeSmartphone.Error.INTERNAL_ERROR( msg );
        }
        catch ( DBusError, IOError err1 )
        {
        }
        // FIXME update modem status!
    }
}
