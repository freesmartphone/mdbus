/*
 * Copyright (C) 2010-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
using GIsiComm;

namespace NokiaIsi
{

/*
 * org.freesmartphone.Info
 */
public class IsiDeviceGetInformation : DeviceGetInformation
{
    /* revision, model, manufacturer, imei */
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        info = new GLib.HashTable<string,Variant>( str_hash, str_equal );

        NokiaIsi.isimodem.info.readManufacturer( ( error, msg ) => {
            info.insert( "manufacturer", error != ErrorCode.OK ? "<unknown>" : msg );
            run.callback();
        } );
        yield;

        NokiaIsi.isimodem.info.readModel( ( error, msg ) => {
            info.insert( "model", error != ErrorCode.OK ? "<unknown>" : msg );
            run.callback();
        } );
        yield;

        NokiaIsi.isimodem.info.readVersion( ( error, msg ) => {
            info.insert( "revision", error != ErrorCode.OK ? "<unknown>" : msg );
            run.callback();
        } );
        yield;

        NokiaIsi.isimodem.info.readSerial( ( error, msg ) => {
            info.insert( "imei", error != ErrorCode.OK ? "<unknown>" : msg );
            run.callback();
        } );
        yield;
    }
}

/*
 * org.freesmartphone.GSM.Device
 */
public class IsiDeviceSetFunctionality : DeviceSetFunctionality
{
    public override async void run( string level, bool autoregister, string pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var value = Constants.instance().deviceFunctionalityStringToStatus( level );

        if ( value == -1 )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Functionality needs to be one of \"minimal\", \"airplane\", or \"full\"." );
        }

        var curlevel = "unknown";
        NokiaIsi.isimodem.mtc.readState( ( err, cur, tgt ) => {
            if ( err == ErrorCode.OK )
            {
                curlevel = NokiaIsi.modem.deviceFunctionalityModemStateToString( cur );
                theModem.logger.debug( @"current level is $curlevel" );
            }
            run.callback();
        } );
        yield;

        if ( curlevel != level )
        {
            assert( theModem.logger.debug( @"setting Functionality to $level") );
            bool on = false;
            bool online = false;

            switch ( level )
            {
                case "full":
                    on = true;
                    online = true;
                    break;
                case "airplane":
                    on = true;
                    break;
            }

            NokiaIsi.isimodem.mtc.setState( on, online, ( err, res ) => {
                if ( err != ErrorCode.OK )
                {
                    throw new FreeSmartphone.GSM.Error.DEVICE_FAILED( "Unknown ISI Error" );
                }
                run.callback();
            } );
            yield;
        }

        var data = theModem.data();
        data.keepRegistration = autoregister;
        if ( pin != "" )
        {
            data.simPin = pin;
            theModem.watchdog.resetUnlockMarker();
        }
        yield gatherSimStatusAndUpdate();
    }
}

} // namespace NokiaIsi

// vim:ts=4:sw=4:expandtab
