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

using GLib;

namespace DBusService {
    const string MODULE_NAME = "fsogsm.dbus_service";
}

class DBusService.Device :
    FreeSmartphone.Info,
    FreeSmartphone.Device.RealtimeClock,
    FreeSmartphone.Device.PowerSupply,
    FreeSmartphone.GSM.Debug,
    FreeSmartphone.GSM.Device,
    FreeSmartphone.GSM.SIM,
    FreeSmartphone.GSM.SMS,
    FreeSmartphone.GSM.Network,
    FreeSmartphone.GSM.Call,
    FreeSmartphone.GSM.PDP,
    FreeSmartphone.GSM.CB,
    FreeSmartphone.GSM.HZ,
    FreeSmartphone.GSM.Monitor,
    FreeSmartphone.GSM.VoiceMail,
    FsoFramework.AbstractObject
{
    //FsoFramework.Subsystem subsystem;
    private static FsoGsm.Modem modem;
    public static Type modemclass;

    public Device( FsoFramework.Subsystem subsystem )
    {
        var modemtype = config.stringValue( "fsogsm", "modem_type", "none" );
        string typename;

        switch ( modemtype )
        {
            case "cinterion_mc75":
                typename = "CinterionMc75Modem";
                break;
            case "dummy":
                typename = "DummyModem";
                break;
            case "freescale_neptune":
                typename = "FreescaleNeptuneModem";
                break;
            case "nokia_isi":
                typename = "NokiaIsiModem";
                break;
            case "singleline":
                typename = "SinglelineModem";
                break;
            case "ti_calypso":
                typename = "TiCalypsoModem";
                break;
            case "qualcomm_htc":
                typename = "QualcommHtcModem";
                break;
            case "qualcomm_palm":
                typename = "QualcommPalmModem";
                break;
            case "samsung":
                typename = "SamsungModem";
                break;
            case "option_gtm601":
                typename = "Gtm601Modem";
                break;
            case "phonesim":
                typename = "PhonesimModem";
                break;
            default:
                logger.error( @"Unsupported modem_type $modemtype" );
                return;
        }

        modemclass = Type.from_name( typename );
        if ( modemclass == Type.INVALID  )
        {
            logger.error( @"Can't find modem for modem_type $modemtype; corresponding modem plugin loaded?" );
            return;
        }

        subsystem.registerObjectForService<FreeSmartphone.Info>( FsoFramework.GSM.ServiceDBusName, FsoFramework.GSM.DeviceServicePath, this );
        subsystem.registerObjectForService<FreeSmartphone.Device.RealtimeClock>( FsoFramework.GSM.ServiceDBusName, FsoFramework.GSM.DeviceServicePath, this );
        subsystem.registerObjectForService<FreeSmartphone.Device.PowerSupply>( FsoFramework.GSM.ServiceDBusName, FsoFramework.GSM.DeviceServicePath, this );
        subsystem.registerObjectForService<FreeSmartphone.GSM.Debug>( FsoFramework.GSM.ServiceDBusName, FsoFramework.GSM.DeviceServicePath, this );
        subsystem.registerObjectForService<FreeSmartphone.GSM.Device>( FsoFramework.GSM.ServiceDBusName, FsoFramework.GSM.DeviceServicePath, this );
        subsystem.registerObjectForService<FreeSmartphone.GSM.SIM>( FsoFramework.GSM.ServiceDBusName, FsoFramework.GSM.DeviceServicePath, this );
        subsystem.registerObjectForService<FreeSmartphone.GSM.SMS>( FsoFramework.GSM.ServiceDBusName, FsoFramework.GSM.DeviceServicePath, this );
        subsystem.registerObjectForService<FreeSmartphone.GSM.Network>( FsoFramework.GSM.ServiceDBusName, FsoFramework.GSM.DeviceServicePath, this );
        subsystem.registerObjectForService<FreeSmartphone.GSM.Call>( FsoFramework.GSM.ServiceDBusName, FsoFramework.GSM.DeviceServicePath, this );
        subsystem.registerObjectForService<FreeSmartphone.GSM.PDP>( FsoFramework.GSM.ServiceDBusName, FsoFramework.GSM.DeviceServicePath, this );
        subsystem.registerObjectForService<FreeSmartphone.GSM.CB>( FsoFramework.GSM.ServiceDBusName, FsoFramework.GSM.DeviceServicePath, this );
        subsystem.registerObjectForService<FreeSmartphone.GSM.HZ>( FsoFramework.GSM.ServiceDBusName, FsoFramework.GSM.DeviceServicePath, this );
        subsystem.registerObjectForService<FreeSmartphone.GSM.Monitor>( FsoFramework.GSM.ServiceDBusName, FsoFramework.GSM.DeviceServicePath, this );
        subsystem.registerObjectForService<FreeSmartphone.GSM.VoiceMail>( FsoFramework.GSM.ServiceDBusName, FsoFramework.GSM.DeviceServicePath, this );

        modem = (FsoGsm.Modem) Object.new( modemclass );
        modem.parent = this;
        modem.hangup.connect( onModemHangup );

        logger.info( @"Ready. Configured for modem $modemtype" );
    }

    public override string repr()
    {
        return "<>";
    }

    private void checkAvailability( FsoGsm.Modem.Status required = FsoGsm.Modem.Status.ALIVE_NO_SIM ) throws FreeSmartphone.Error
    {
        if ( modem == null )
        {
            throw new FreeSmartphone.Error.UNAVAILABLE( "There is no underlying hardware present... stop talking to a vapourware modem!" );
        }

        if ( ( modem.status() < required ) || ( modem.status() >= FsoGsm.Modem.Status.SUSPENDING ) )
        {
            throw new FreeSmartphone.Error.UNAVAILABLE( @"This function is not available while modem is in state $(modem.status())" );
        }
    }

    private void onModemHangup()
    {
        logger.warning( "Modem no longer responding; trying to reopen in 5 seconds" );
        Timeout.add_seconds( 5, () => {
            onModemHangupAsync();
            return false;
        } );
    }

    private async void onModemHangupAsync()
    {
        var ok = yield enable();
        if ( !ok )
        {
            onModemHangup();
        }
    }

    public async bool enable()
    {
        var ok = yield modem.open();
        if ( !ok )
        {
            logger.error( "Can't open modem" );
            return false;
        }
        else
        {
            logger.info( "Modem opened successfully" );
            return true;
        }
    }

    public async void disable()
    {
        yield modem.close();
        logger.info( "Modem closed successfully" );
    }

    public async void suspend()
    {
        var ok = yield modem.suspend();
        if ( ok )
        {
            logger.info( "Modem suspended successfully" );
        }
        else
        {
            logger.warning( "Modem not suspended; prepare yourself for spurious wakeups" );
        }
    }

    public async void resume()
    {
        var ok = yield modem.resume();
        if ( ok )
        {
            logger.info( "Modem resumed successfully" );
        }
        else
        {
            logger.warning( "Modem did not resume correctly" );
        }
    }

    //
    // DBUS (org.freesmartphone.Info)
    //
    public async GLib.HashTable<string,GLib.Variant> get_info() throws FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.DeviceGetInformation>();
        try
        {
            yield m.run();
        }
        catch ( FreeSmartphone.GSM.Error e )
        {
            throw new FreeSmartphone.Error.SYSTEM_ERROR( e.message );
        }
        return m.info;
    }

    //
    // DBUS (org.freesmartphone.Device.RealtimeClock)
    //
    public async int get_current_time() throws FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.DeviceGetCurrentTime>();
        try
        {
            yield m.run();
        }
        catch ( FreeSmartphone.GSM.Error e )
        {
            throw new FreeSmartphone.Error.SYSTEM_ERROR( e.message );
        }
        return m.since_epoch;
    }

    public async void set_current_time( int seconds_since_epoch ) throws FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.DeviceSetCurrentTime>();
        try
        {
            yield m.run( seconds_since_epoch );
        }
        catch ( FreeSmartphone.GSM.Error e )
        {
            throw new FreeSmartphone.Error.SYSTEM_ERROR( e.message );
        }
    }

    public async int get_wakeup_time() throws FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.DeviceGetAlarmTime>();
        try
        {
            yield m.run();
        }
        catch ( FreeSmartphone.GSM.Error e )
        {
            throw new FreeSmartphone.Error.SYSTEM_ERROR( e.message );
        }
        return m.since_epoch;
    }

    public async void set_wakeup_time( int seconds_since_epoch ) throws FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.DeviceSetAlarmTime>();
        try
        {
            yield m.run( seconds_since_epoch );
        }
        catch ( FreeSmartphone.GSM.Error e )
        {
            throw new FreeSmartphone.Error.SYSTEM_ERROR( e.message );
        }
        this.wakeup_time_changed( seconds_since_epoch ); // DBUS SIGNAL
    }

    //
    // DBUS (org.freesmartphone.Device.PowerSupply.*)
    //
    public async FreeSmartphone.Device.PowerStatus get_power_status() throws DBusError, IOError, FreeSmartphone.Error
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.DeviceGetPowerStatus>();
        try
        {
            yield m.run();
            return m.status;
        }
        catch ( GLib.Error e ) // get_power_status() should not raise any errors
        {
            return FreeSmartphone.Device.PowerStatus.UNKNOWN;
        }
    }

    public async int get_capacity() throws DBusError, IOError, FreeSmartphone.Error
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.DeviceGetPowerStatus>();
        try
        {
            yield m.run();
            return m.level;
        }
        catch ( GLib.Error e ) // get_capacity() should not raise any errors
        {
            return -1;
        }
    }

    //
    // DBUS (org.freesmartphone.GSM.Debug.*)
    //
    public async string debug_command( string command, string channel ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.DebugCommand>();
        yield m.run( command, channel );
        return m.response;
    }

    public async void debug_inject_response( string response, string channel ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.DebugInjectResponse>();
        yield m.run( response, channel );
    }

    public async void debug_ping() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.DebugPing>();
        yield m.run();
    }

    //
    // DBUS (org.freesmartphone.GSM.Device.*)
    //
    public async void get_functionality( out string level, out bool autoregister, out string pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.DeviceGetFunctionality>();
        yield m.run();
        level = m.level;
        autoregister = m.autoregister;
        pin = m.pin;
    }

    public async GLib.HashTable<string,GLib.Variant> get_features() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.DeviceGetFeatures>();
        yield m.run();
        return m.features;
    }

    public async bool get_microphone_muted() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.DeviceGetMicrophoneMuted>();
        yield m.run();
        return m.muted;
    }

    public async int get_speaker_volume() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.DeviceGetSpeakerVolume>();
        yield m.run();
        return m.volume;
    }

    public async void set_functionality( string level, bool autoregister, string pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        yield modem.setFunctionality( level, autoregister, pin );
    }

    public async void set_microphone_muted( bool muted ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.DeviceSetMicrophoneMuted>();
        yield m.run( muted );
    }

    public async void set_speaker_volume( int volume ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.DeviceSetSpeakerVolume>();
        yield m.run( volume );
    }

    public async FreeSmartphone.GSM.DeviceStatus get_device_status() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        return modem.externalStatus();
    }

    //
    // DBUS (org.freesmartphone.GSM.SIM.*)
    //
    public async void change_auth_code( string old_pin, string new_pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_SIM_READY );
        var m = modem.createMediator<FsoGsm.SimChangeAuthCode>();
        yield m.run( old_pin, new_pin );
    }

    public async void delete_entry( string category, int index ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_SIM_READY );
        var m = modem.createMediator<FsoGsm.SimDeleteEntry>();
        yield m.run( category, index );
    }

    public async void delete_message( int index ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_SIM_READY );
        var m = modem.createMediator<FsoGsm.SimDeleteMessage>();
        yield m.run( index );
    }

    public async bool get_auth_code_required() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_SIM_READY );
        var m = modem.createMediator<FsoGsm.SimGetAuthCodeRequired>();
        yield m.run();
        return m.required;
    }

    public async FreeSmartphone.GSM.SIMAuthStatus get_auth_status() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.SimGetAuthStatus>();
        yield m.run();
        return m.status;
    }

    public async FreeSmartphone.GSM.SIMHomeZone[] get_home_zone_parameters() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_SIM_READY );
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async void get_phonebook_info( string category, out int slots, out int numberlength, out int namelength ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_SIM_READY );
        var m = modem.createMediator<FsoGsm.SimGetPhonebookInfo>();
        yield m.run( category, out slots, out numberlength, out namelength );
    }

    public async string get_service_center_number() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_SIM_READY );
        var m = modem.createMediator<FsoGsm.SimGetServiceCenterNumber>();
        yield m.run();
        return m.number;
    }

    public async GLib.HashTable<string,GLib.Variant> get_sim_info() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_SIM_LOCKED ); // or READY?
        var m = modem.createMediator<FsoGsm.SimGetInformation>();
        yield m.run();
        return m.info;
    }

    public async GLib.HashTable<string,GLib.Variant> get_unlock_counters() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_SIM_LOCKED );
        var m = modem.createMediator<FsoGsm.SimGetUnlockCounters>();
        yield m.run();
        return m.counters;
    }

    public async void retrieve_message( int index, out string status, out string number, out string contents, out GLib.HashTable<string,GLib.Variant> properties ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_SIM_READY );
        var m = modem.createMediator<FsoGsm.SimRetrieveMessage>();
        yield m.run( index, out status, out number, out contents, out properties );
    }

    public async FreeSmartphone.GSM.SIMEntry[] retrieve_phonebook( string category, int mindex, int maxdex ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_SIM_READY );
        var m = modem.createMediator<FsoGsm.SimRetrievePhonebook>();
        yield m.run( category, mindex, maxdex );
        return m.phonebook;
    }

    public async void send_auth_code( string pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_SIM_LOCKED );
        var m = modem.createMediator<FsoGsm.SimSendAuthCode>();
        yield m.run( pin );
    }

    public async string send_generic_sim_command( string command ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_SIM_READY );
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async string send_restricted_sim_command( int command, int fileid, int p1, int p2, int p3, string data ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_SIM_READY );
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async void send_stored_message( int index, out int transaction_index, out string timestamp ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        var m = modem.createMediator<FsoGsm.SimSendStoredMessage>();
        yield m.run( index );
        transaction_index = m.transaction_index;
        timestamp = m.timestamp;
    }

    public async void set_auth_code_required( bool check, string pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_SIM_READY );
        var m = modem.createMediator<FsoGsm.SimSetAuthCodeRequired>();
        yield m.run( check, pin );
    }

    public async void set_service_center_number( string number ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_SIM_READY );
        var m = modem.createMediator<FsoGsm.SimSetServiceCenterNumber>();
        yield m.run( number );
    }

    public async void store_entry( string category, int index, string name, string number ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_SIM_READY );
        var m = modem.createMediator<FsoGsm.SimWriteEntry>();
        yield m.run( category, index, number, name );
    }

    public async int store_message( string recipient_number, string contents, GLib.HashTable<string,GLib.Variant> properties ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_SIM_READY );
        var m = modem.createMediator<FsoGsm.SimStoreMessage>();
        yield m.run( recipient_number, contents, false );
        return m.memory_index;
    }

    public async void unlock( string puk, string new_pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_SIM_LOCKED );
        var m = modem.createMediator<FsoGsm.SimUnlock>();
        yield m.run( puk, new_pin );
    }

    //
    // DBUS (org.freesmartphone.GSM.SMS.*)
    //

    public async uint get_size_for_text_message( string contents ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.SmsGetSizeForTextMessage>();
        yield m.run( contents );
        return m.size;
    }

    public async FreeSmartphone.GSM.SIMMessage[] retrieve_text_messages() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_SIM_READY );
        var m = modem.createMediator<FsoGsm.SmsRetrieveTextMessages>();
        yield m.run();
        return m.messagebook;
    }

    public async void send_text_message( string recipient_number, string contents, bool want_report, out int transaction_index, out string timestamp ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        var m = modem.createMediator<FsoGsm.SmsSendTextMessage>();
        yield m.run( recipient_number, contents, want_report );
        transaction_index = m.transaction_index;
        timestamp = m.timestamp;
    }

    //
    // DBUS (org.freesmartphone.GSM.Network.*)
    //
    public async void disable_call_forwarding( string reason, string class_ ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async void enable_call_forwarding( string reason, string class_, string number, int timeout ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async GLib.HashTable<string,GLib.Variant> get_call_forwarding( string reason ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async FreeSmartphone.GSM.CallingIdentificationStatus get_calling_identification() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        var m = modem.createMediator<FsoGsm.NetworkGetCallingId>();
        yield m.run();
        return m.status;
    }

    public async void get_time_report( out int time, out int timestamp, out int zone, out int zonestamp ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var ltr = modem.data().networkTimeReport;
        time = ltr.time;
        timestamp = ltr.timestamp;
        zone = ltr.zone;
        zonestamp = ltr.zonestamp;
    }

    public async int get_signal_strength() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        var m = modem.createMediator<FsoGsm.NetworkGetSignalStrength>();
        yield m.run();
        return m.signal;
    }

    public async GLib.HashTable<string,GLib.Variant> get_status() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.NetworkGetStatus>();
        yield m.run();
        return m.status;
    }

    public async FreeSmartphone.GSM.NetworkProvider[] list_providers() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.NetworkListProviders>();
        yield m.run();
        return m.providers;
    }

    public async void register_() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.NetworkRegister>();
        yield m.run();
    }

    public async void register_with_provider( string operator_code ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.NetworkRegisterWithProvider>();
        yield m.run( operator_code );
    }

    public async void send_ussd_request( string request ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        var m = modem.createMediator<FsoGsm.NetworkSendUssdRequest>();
        yield m.run( request );
    }

    public async void set_calling_identification( FreeSmartphone.GSM.CallingIdentificationStatus status ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        var m = modem.createMediator<FsoGsm.NetworkSetCallingId>();
        yield m.run( status );
    }

    public async void unregister() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        var m = modem.createMediator<FsoGsm.NetworkUnregister>();
        yield m.run();
    }

    //
    // DBUS (org.freesmartphone.GSM.Call.*)
    //
    public async void activate( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        var m = modem.createMediator<FsoGsm.CallActivate>();
        yield m.run( id );
    }

    public async void activate_conference( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async void emergency( string number ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async void hold_active() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        var m = modem.createMediator<FsoGsm.CallHoldActive>();
        yield m.run();
    }

    public async int initiate( string number, string ctype ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        var m = modem.createMediator<FsoGsm.CallInitiate>();
        yield m.run( number, ctype );
        return m.id;
    }

    public async void join() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async FreeSmartphone.GSM.CallDetail[] list_calls() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        var m = modem.createMediator<FsoGsm.CallListCalls>();
        yield m.run();
        return m.calls;
    }

    public async void release( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        var m = modem.createMediator<FsoGsm.CallRelease>();
        yield m.run( id );
    }

    public async void release_all() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        var m = modem.createMediator<FsoGsm.CallReleaseAll>();
        yield m.run();
    }

    public async void release_held() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async void send_dtmf( string tones ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        FsoGsm.validateDtmfTones( tones );
        var m = modem.createMediator<FsoGsm.CallSendDtmf>();
        yield m.run( tones );
    }

    public async void transfer( string number ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    //
    // DBUS (org.freesmartphone.GSM.PDP.*)
    //
    public async void activate_context() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        var m = modem.createMediator<FsoGsm.PdpActivateContext>();
        yield m.run();
    }

    public async void deactivate_context() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        var m = modem.createMediator<FsoGsm.PdpDeactivateContext>();
        yield m.run();
    }

    public async void get_context_status( out FreeSmartphone.GSM.ContextStatus status, out GLib.HashTable<string,GLib.Variant> properties ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        status = modem.pdphandler.status;
        properties = modem.pdphandler.properties;
    }

    public async void get_credentials( out string apn, out string username, out string password ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.PdpGetCredentials>();
        yield m.run();
        apn = m.apn;
        username = m.username;
        password = m.password;
    }

    public async bool get_roaming_allowed () throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, GLib.DBusError, GLib.IOError
    {
        checkAvailability();
        return modem.data().roamingAllowed;
    }

    public async void set_roaming_allowed (bool state) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, GLib.DBusError, GLib.IOError
    {
        checkAvailability();
        modem.data().roamingAllowed = state;
        yield modem.pdphandler.syncStatus();
    }

    public async void internal_status_update( string status, GLib.HashTable<string,GLib.Variant> properties ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        yield modem.pdphandler.statusUpdate( status, properties );
    }

    public async void set_credentials( string apn, string username, string password ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.PdpSetCredentials>();
        yield m.run( apn, username, password );
    }

    //
    // DBUS (org.freesmartphone.GSM.CB.*)
    //
    public async string get_cell_broadcast_subscriptions() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        var m = modem.createMediator<FsoGsm.CbGetCellBroadcastSubscriptions>();
        yield m.run();
        return m.subscriptions;
    }

    public async void set_cell_broadcast_subscriptions( string subscriptions ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        var m = modem.createMediator<FsoGsm.CbSetCellBroadcastSubscriptions>();
        yield m.run( subscriptions );
    }

    //
    // DBUS (org.freesmartphone.GSM.HZ.*)
    //
    public async string get_home_zone_status() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async string[] get_known_home_zones() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_SIM_READY );
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    //
    // DBUS (org.freesmartphone.GSM.Monitor.*)
    //
    public async GLib.HashTable<string,GLib.Variant> get_serving_cell_information() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.MonitorGetServingCellInformation>();
        yield m.run();
        return m.cell;
    }

    public async GLib.HashTable<string,GLib.Variant>[] get_neighbour_cell_information() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.MonitorGetNeighbourCellInformation>();
        yield m.run();
        return m.cells;
    }

    //
    // DBUS (org.freesmartphone.GSM.VoiceMail.*)
    //
    public async string get_voice_mailbox_number() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.VoiceMailboxGetNumber>();
        yield m.run();
        return m.number;
    }

    public async void set_voice_mailbox_number( string number ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.VoiceMailboxSetNumber>();
        yield m.run( number );
    }

    public async string[] get_stored_voice_mails() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
        //var m = modem.createMediator<FsoGsm.VoiceMailboxGetRecordings>();
        //yield m.run( number );
    }
}

/**
 * @class DBusService.Resource
 **/
public class DBusService.Resource : FsoFramework.AbstractDBusResource
{
    public Resource( FsoFramework.Subsystem subsystem )
    {
        base( "GSM", subsystem );
    }

    public override async void enableResource() throws FreeSmartphone.ResourceError
    {
        logger.debug( "Enabling GSM resource..." );
        var ok = yield device.enable();
        if ( !ok )
        {
            throw new FreeSmartphone.ResourceError.UNABLE_TO_ENABLE( "Can't open the modem." );
        }
    }

    public override async void disableResource()
    {
        logger.debug( "Disabling GSM resource..." );
        yield device.disable();
    }

    public override async void suspendResource()
    {
        logger.debug( "Suspending GSM resource..." );
        yield device.suspend();
    }

    public override async void resumeResource()
    {
        logger.debug( "Resuming GSM resource..." );
        yield device.resume();
    }

    public override async GLib.HashTable<string,GLib.Variant?> dependencies()
    {
        var dependencies = new GLib.HashTable<string,GLib.Variant?>( GLib.str_hash, GLib.str_equal );

        // Service dependencies can be defined dynamically by the plugins with accessing
        // the theServiceDependencies global variable.
        string services = "";
        bool first = true;
        foreach ( var service in FsoGsm.theServiceDependencies )
        {
            if ( !first )
                services += ",";
            services += service;
            first = false;
        }

        dependencies.insert( "services", services );

        return dependencies;
    }
}

DBusService.Device device;
DBusService.Resource resource;

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    device = new DBusService.Device( subsystem );
    if ( DBusService.Device.modemclass != Type.INVALID )
    {
        resource = new DBusService.Resource( subsystem );
    }
    return DBusService.MODULE_NAME;
}

/**
 * This function gets called on subsystem shutdown time.
 **/
public static void fso_shutdown_function() throws Error
{
#if DEBUG
    debug( "SHUTDOWN ENTER" );
#endif
    running = true;
    async_helper();
    while ( running )
    {
        GLib.MainContext.default().iteration( true );
    }
#if DEBUG
    debug( "SHUTDOWN LEAVE" );
#endif
}

static bool running;
internal async void async_helper()
{
#if DEBUG
    debug( "ASYNC_HELPER ENTER" );
#endif
    yield resource.disableResource();
    running = false;
#if DEBUG
    debug( "ASYNC_HELPER_DONE" );
#endif
}

/**
 * Module init function, DON'T REMOVE THIS!
 **/
[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsogsm.dbus_service fso_register_function" );
}

/**
 * This function gets called on plugin load time.
 * @return false, if the plugin operating conditions are present.
 * @note Some versions of glib contain a bug that leads to a SIGSEGV
 * in g_module_open, if you return true here.
 **/
/*public static bool g_module_check_init( void* m )
{
    var ok = FsoFramework.FileHandling.isPresent( Kernel26.SYS_CLASS_LEDS );
    return (!ok);
}
*/

// vim:ts=4:sw=4:expandtab
