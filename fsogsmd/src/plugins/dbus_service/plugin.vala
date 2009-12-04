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

using GLib;

namespace DBusService {
    const string MODULE_NAME = "fsogsm.dbus_service";
}

class DBusService.Device :
    FreeSmartphone.Device.RealtimeClock,
    FreeSmartphone.GSM.Debug,
    FreeSmartphone.GSM.Device,
    FreeSmartphone.GSM.SIM,
    FreeSmartphone.GSM.SMS,
    FreeSmartphone.GSM.Network,
    XFreeSmartphone.GSM.Call,
    FsoFramework.AbstractObject
{
    FsoFramework.Subsystem subsystem;
    private static FsoGsm.Modem modem;
    public static Type modemclass;

    public Device( FsoFramework.Subsystem subsystem )
    {
        var modemtype = config.stringValue( "fsogsm", "modem_type", "DummyModem" );
        if ( modemtype == "DummyModem" )
        {
            logger.critical( "modem_type not specified and DummyModem not implemented yet" );
            return;
        }
        string typename;

        switch ( modemtype )
        {
            case "singleline":
                typename = "SinglelineModem";
                break;
            case "ti_calypso":
                typename = "TiCalypsoModem";
                break;
            case "qualcomm_htc":
                typename = "QualcommHtcModem";
                break;
            case "freescale_neptune":
                typename = "FreescaleNeptuneModem";
                break;
            case "cinterion_mc75":
                typename = "CinterionMc75Modem";
                break;
            default:
                logger.critical( "Invalid modem_type '%s'; corresponding modem plugin loaded?".printf( modemtype ) );
                return;
        }

        modemclass = Type.from_name( typename );
        if ( modemclass == Type.INVALID  )
        {
            logger.warning( "Can't find modem for modem_type = '%s'".printf( modemtype ) );
            return;
        }

        subsystem.registerServiceName( FsoFramework.GSM.ServiceDBusName );
        subsystem.registerServiceObject( FsoFramework.GSM.ServiceDBusName, FsoFramework.GSM.DeviceServicePath, this );

        modem = (FsoGsm.Modem) Object.new( modemclass );

        modem.parent = this;

        logger.info( "Ready. Configured for modem '%s'".printf( modemtype ) );
    }

    public override string repr()
    {
        return "<>";
    }

    public void enable()
    {
        if ( !modem.open() )
            logger.error( "Can't open modem" );
        else
            logger.info( "Modem opened successfully" );
    }

    public void disable()
    {
        modem.close();
        logger.info( "Modem closed successfully" );
    }

    public void suspend()
    {
        logger.critical( "Not yet implemented" );
    }

    public void resume()
    {
        logger.critical( "Not yet implemented" );
    }

    //
    // DBUS (org.freesmartphone.Device.RealtimeClock)
    //

    public async int get_current_time() throws FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.DeviceGetCurrentTime>();
        yield m.run();
        return m.since_epoch;
    }

    public async void set_current_time( int seconds_since_epoch ) throws FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.DeviceSetCurrentTime>();
        yield m.run( seconds_since_epoch );
    }

    public async int get_wakeup_time() throws FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.DeviceGetAlarmTime>();
        yield m.run();
        return m.since_epoch;
    }

    public async void set_wakeup_time( int seconds_since_epoch ) throws FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.DeviceSetAlarmTime>();
        yield m.run( seconds_since_epoch );
        this.wakeup_time_changed( seconds_since_epoch ); // DBUS SIGNAL
    }

    //
    // DBUS (org.freesmartphone.GSM.Debug.*)
    //
    public async string debug_at_command( string command, string channel ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.DebugAtCommand>();
        yield m.run( command, channel );
        return m.response;
    }
    public async void debug_inject_at_response( string response, string channel ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.DebugInjectAtResponse>();
        yield m.run( response, channel );
    }

    //
    // DBUS (org.freesmartphone.GSM.Device.*)
    //
    public async bool get_antenna_power() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.DeviceGetAntennaPower>();
        yield m.run();
        return m.antenna_power;
    }

    public async string get_functionality() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.DeviceGetFunctionality>();
        yield m.run();
        return m.level;
    }

    public async GLib.HashTable<string,GLib.Value?> get_info() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.DeviceGetInformation>();
        yield m.run();
        return m.info;
    }

    public async GLib.HashTable<string,GLib.Value?> get_features() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.DeviceGetFeatures>();
        yield m.run();
        return m.features;
    }

    public async bool get_microphone_muted() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.DeviceGetMicrophoneMuted>();
        yield m.run();
        return m.muted;
    }

    public async bool get_sim_buffers_sms() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.DeviceGetSimBuffersSms>();
        yield m.run();
        return m.buffers;
    }

    public async int get_speaker_volume() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.DeviceGetSpeakerVolume>();
        yield m.run();
        return m.volume;
    }

    public async void set_antenna_power( bool antenna_power ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.UNSUPPORTED( "Please use org.freesmartphone.GSM.Device.SetFunctionality instead." );
    }

    public async void set_functionality( string level ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.DeviceSetFunctionality>();
        yield m.run( level );
    }

    public async void set_microphone_muted( bool muted ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.DeviceSetMicrophoneMuted>();
        yield m.run( muted );
    }

    public async void set_sim_buffers_sms( bool sim_buffers_sms ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.DeviceSetSimBuffersSms>();
        yield m.run( sim_buffers_sms );
    }

    public async void set_speaker_volume( int volume ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.DeviceSetSpeakerVolume>();
        yield m.run( volume );
    }

    public async void get_power_status( out string status, out int level ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.DeviceGetPowerStatus>();
        yield m.run();
        status = m.status;
        level = m.level;
    }

    //
    // DBUS (org.freesmartphone.GSM.SIM.*)
    //
    public async void change_auth_code( string old_pin, string new_pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.SimChangeAuthCode>();
        yield m.run( old_pin, new_pin );
    }

    public async void delete_entry( string category, int index ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async void delete_message( int index ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async bool get_auth_code_required() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.SimGetAuthCodeRequired>();
        yield m.run();
        return m.required;
    }

    public async FreeSmartphone.GSM.SIMAuthStatus get_auth_status() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.SimGetAuthStatus>();
        yield m.run();
        return m.status;
    }

    public async FreeSmartphone.GSM.SIMHomezone[] get_home_zones() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async string get_issuer() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Deprecated. Please use org.freesmartphone.GSM.SIM.GetSimInfo()" );
    }

    public async GLib.HashTable<string,GLib.Value?> get_messagebook_info() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async GLib.HashTable<string,GLib.Value?> get_phonebook_info( string category ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async GLib.HashTable<string,string> get_provider_list() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async string get_service_center_number() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.SimGetServiceCenterNumber>();
        yield m.run();
        return m.number;
    }

    public async GLib.HashTable<string,GLib.Value?> get_sim_info() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.SimGetInformation>();
        yield m.run();
        return m.info;
    }

    public async bool get_sim_ready() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async string[] list_phonebooks() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.SimListPhonebooks>();
        yield m.run();
        return m.phonebooks;
    }

    public async void retrieve_entry( string category, int index, out string name, out string number ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async void retrieve_message( int index, out string status, out string sender_number, out string contents, out GLib.HashTable<string,GLib.Value?> properties ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async FreeSmartphone.GSM.SIMMessage[] retrieve_messagebook( string category ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.SimRetrieveMessagebook>();
        yield m.run( category );
        return m.messagebook;
    }

    public async FreeSmartphone.GSM.SIMEntry[] retrieve_phonebook( string category ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.SimRetrievePhonebook>();
        yield m.run( category );
        return m.phonebook;
    }

    public async void send_auth_code( string pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.SimSendAuthCode>();
        yield m.run( pin );
    }

    public async string send_generic_sim_command( string command ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async string send_restricted_sim_command( int command, int fileid, int p1, int p2, int p3, string data ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async void send_stored_message( int index, out int transaction_index, out string timestamp ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async void set_auth_code_required( bool check, string pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.SimSetAuthCodeRequired>();
        yield m.run( check, pin );
    }

    public async void set_service_center_number( string number ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.SimSetServiceCenterNumber>();
        yield m.run( number );
    }

    public async void store_entry( string category, int index, string name, string number ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async int store_message( string recipient_number, string contents, GLib.HashTable<string,GLib.Value?> properties ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async void unlock( string puk, string new_pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.SimUnlock>();
        yield m.run( puk, new_pin );
    }

    //
    // DBUS (org.freesmartphone.GSM.SMS.*)
    //
    public async void ack_message( string contents, GLib.HashTable<string,GLib.Value?> properties ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async void nack_message( string contents, GLib.HashTable<string,GLib.Value?> properties ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async void send_message( string recipient_number, string contents, GLib.HashTable<string,GLib.Value?> properties, out int transaction_index, out string timestamp ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async void send_text_message( string recipient_number, string contents, bool want_report, out int transaction_index, out string timestamp ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.SmsSendMessage>();
        yield m.run( recipient_number, contents, want_report );
        transaction_index = m.transaction_index;
        timestamp = m.timestamp;
    }

    public async uint get_size_for_text_message( string contents ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.SmsGetSizeForMessage>();
        yield m.run( contents );
        return m.size;
    }

    //
    // DBUS (org.freesmartphone.GSM.Network.*)
    //
    public async void disable_call_forwarding( string reason, string class_ ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async void enable_call_forwarding( string reason, string class_, string number, int timeout ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async GLib.HashTable<string,GLib.Value?> get_call_forwarding( string reason ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async string get_calling_identification() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async void get_network_country_code( out string dial_code, out string country_name ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async int get_signal_strength() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.NetworkGetSignalStrength>();
        yield m.run();
        return m.signal;
    }

    public async GLib.HashTable<string,GLib.Value?> get_status() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.NetworkGetStatus>();
        yield m.run();
        return m.status;
    }

    public async FreeSmartphone.GSM.NetworkProvider[] list_providers() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.NetworkListProviders>();
        yield m.run();
        return m.providers;
    }

    public async void register_() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.NetworkRegister>();
        yield m.run();
    }

    public async void register_with_provider( string operator_code ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async void send_ussd_request( string request ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async void set_calling_identification( string visible ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async void unregister() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    //
    // DBUS (org.freesmartphone.GSM.Call.*)
    //
    public async void activate( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.CallActivate>();
        yield m.run( id );
    }

    public async void activate_conference( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async void emergency( string number ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async void hold_active() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.CallHoldActive>();
        yield m.run();
    }

    public async int initiate( string number, string ctype ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.CallInitiate>();
        yield m.run( number, ctype );
        return m.id;
    }

    public async void join() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async XFreeSmartphone.GSM.CallDetail[] list_calls() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.CallListCalls>();
        yield m.run();
        return m.calls;
    }

    public async void release( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.CallRelease>();
        yield m.run( id );
    }

    public async void release_all() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.CallReleaseAll>();
        yield m.run();
    }

    public async void release_held() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async void send_dtmf( string tones ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = modem.createMediator<FsoGsm.CallSendDtmf>();
        yield m.run( tones );
    }

    public async void transfer( string number ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
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

    public override async void enableResource()
    {
        logger.debug( "Enabling GSM resource..." );
        device.enable();
    }

    public override async void disableResource()
    {
        logger.debug( "Disabling GSM resource..." );
        device.disable();
    }

    public override async void suspendResource()
    {
        logger.debug( "Suspending GSM resource..." );
        device.suspend();
    }

    public override async void resumeResource()
    {
        logger.debug( "Resuming GSM resource..." );
        device.resume();
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
    debug( "SHUTDOWN ENTER" );
    running = true;
    async_helper();
    while ( running )
    {
        GLib.MainContext.default().iteration( true );
    }
    debug( "SHUTDOWN LEAVE" );
}

static bool running;
internal async void async_helper()
{
    debug( "ASYNC_HELPER ENTER" );
    yield resource.disableResource();
    running = false;
    debug( "ASYNC_HELPER_DONE" );
}

/**
 * Module init function, DON'T REMOVE THIS!
 **/
[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    debug( "fsogsmd.dbus_service fso_register_function" );
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
