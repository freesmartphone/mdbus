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
    const string MODULE_NAME = "fsogps.dbus_service";
}

class DBusService.Device :
    FsoFramework.AbstractObject
{
    FsoFramework.Subsystem subsystem;
    private static FsoGps.Receiver receiver;
    public static Type receiverclass;

    public Device( FsoFramework.Subsystem subsystem )
    {
        var gpstype = config.stringValue( "fsogps", "receiver_type", "DummyReceiver" );
        if ( gpstype == "DummyReceiver" )
        {
            logger.critical( "receiver_type not specified and DummyReceiver not implemented yet" );
            return;
        }
        string typename;

        switch ( gpstype )
        {
            case "nmea":
                typename = "NmeaReceiver";
                break;
            default:
                logger.critical( "Invalid receiver_type '%s'; corresponding receiver plugin loaded?".printf( gpstype ) );
                return;
        }

        receiverclass = Type.from_name( typename );
        if ( receiverclass == Type.INVALID  )
        {
            logger.warning( "Can't find receiver for receiver_type = '%s'".printf( gpstype ) );
            return;
        }

        subsystem.registerServiceName( FsoFramework.GPS.ServiceDBusName );
        subsystem.registerServiceObject( FsoFramework.GPS.ServiceDBusName, FsoFramework.GPS.DeviceServicePath, this );

        receiver = (FsoGps.Receiver) Object.new( receiverclass );
        receiver.parent = this;

        logger.info( "Ready. Configured for receiver '%s'".printf( gpstype ) );
    }

    public override string repr()
    {
        return "<DBusService>";
    }

    public void enable()
    {
        if ( !receiver.open() )
            logger.error( "Can't open receiver" );
        else
            logger.info( "GPS receiver opened successfully" );
    }

    public void disable()
    {
        receiver.close();
        logger.info( "GPS receiver closed successfully" );
    }

    public void suspend()
    {
        logger.critical( "Not yet implemented" );
    }

    public void resume()
    {
        logger.critical( "Not yet implemented" );
    }

    /*
    //
    // DBUS (org.freesmartphone.Device.RealtimeClock)
    //

    public async int get_current_time() throws FreeSmartphone.Error, DBus.Error
    {
        var m = receiver.createMediator<FsoGps.DeviceGetCurrentTime>();
        yield m.run();
        return m.since_epoch;
    }

    public async void set_current_time( int seconds_since_epoch ) throws FreeSmartphone.Error, DBus.Error
    {
        var m = receiver.createMediator<FsoGps.DeviceSetCurrentTime>();
        yield m.run( seconds_since_epoch );
    }

    public async int get_wakeup_time() throws FreeSmartphone.Error, DBus.Error
    {
        var m = receiver.createMediator<FsoGps.DeviceGetAlarmTime>();
        yield m.run();
        return m.since_epoch;
    }

    public async void set_wakeup_time( int seconds_since_epoch ) throws FreeSmartphone.Error, DBus.Error
    {
        var m = receiver.createMediator<FsoGps.DeviceSetAlarmTime>();
        yield m.run( seconds_since_epoch );
        this.wakeup_time_changed( seconds_since_epoch ); // DBUS SIGNAL
    }

    // DBUS SIGNALS
    public void wakeup_time_changed( int seconds_since_epoch );
    public void alarm( int seconds_since_epoch );

    //
    // DBUS (org.freesmartphone.GSM.Device.*)
    //
    public async bool get_antenna_power() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = receiver.createMediator<FsoGps.DeviceGetAntennaPower>();
        yield m.run();
        return m.antenna_power;
    }

    public async string get_functionality() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = receiver.createMediator<FsoGps.DeviceGetFunctionality>();
        yield m.run();
        return m.level;
    }

    public async GLib.HashTable<string,GLib.Value?> get_info() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = receiver.createMediator<FsoGps.DeviceGetInformation>();
        yield m.run();
        return m.info;
    }

    public async GLib.HashTable<string,GLib.Value?> get_features() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = receiver.createMediator<FsoGps.DeviceGetFeatures>();
        yield m.run();
        return m.features;
    }

    public async bool get_microphone_muted() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = receiver.createMediator<FsoGps.DeviceGetMicrophoneMuted>();
        yield m.run();
        return m.muted;
    }

    public async bool get_sim_buffers_sms() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = receiver.createMediator<FsoGps.DeviceGetSimBuffersSms>();
        yield m.run();
        return m.buffers;
    }

    public async int get_speaker_volume() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = receiver.createMediator<FsoGps.DeviceGetSpeakerVolume>();
        yield m.run();
        return m.volume;
    }

    public async void set_antenna_power( bool antenna_power ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.UNSUPPORTED( "Please use org.freesmartphone.GSM.Device.SetFunctionality instead." );
    }

    public async void set_functionality( string level ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = receiver.createMediator<FsoGps.DeviceSetFunctionality>();
        yield m.run( level );
    }

    public async void set_microphone_muted( bool muted ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = receiver.createMediator<FsoGps.DeviceSetMicrophoneMuted>();
        yield m.run( muted );
    }

    public async void set_sim_buffers_sms( bool sim_buffers_sms ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = receiver.createMediator<FsoGps.DeviceSetSimBuffersSms>();
        yield m.run( sim_buffers_sms );
    }

    public async void set_speaker_volume( int volume ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = receiver.createMediator<FsoGps.DeviceSetSpeakerVolume>();
        yield m.run( volume );
    }

    public async void get_power_status( out string status, out int level ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = receiver.createMediator<FsoGps.DeviceGetPowerStatus>();
        yield m.run();
        status = m.status;
        level = m.level;
    }

    //
    // DBUS (org.freesmartphone.GSM.SIM.*)
    //
    public async void change_auth_code( string old_pin, string new_pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = receiver.createMediator<FsoGps.SimChangeAuthCode>();
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
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async FreeSmartphone.GSM.SIMAuthStatus get_auth_status() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async FreeSmartphone.GSM.SIMHomezone[] get_home_zones() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async string get_issuer() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
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
        var m = receiver.createMediator<FsoGps.SimGetServiceCenterNumber>();
        yield m.run();
        return m.number;
    }

    public async GLib.HashTable<string,GLib.Value?> get_sim_info() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = receiver.createMediator<FsoGps.SimGetInformation>();
        yield m.run();
        return m.info;
    }

    public async bool get_sim_ready() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async string[] list_phonebooks() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = receiver.createMediator<FsoGps.SimListPhonebooks>();
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
        var m = receiver.createMediator<FsoGps.SimRetrieveMessagebook>();
        yield m.run( category );
        return m.messagebook;
    }

    public async FreeSmartphone.GSM.SIMEntry[] retrieve_phonebook( string category ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = receiver.createMediator<FsoGps.SimRetrievePhonebook>();
        yield m.run( category );
        return m.phonebook;
    }

    public async void send_auth_code( string pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = receiver.createMediator<FsoGps.SimSendAuthCode>();
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
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async void set_service_center_number( string number ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = receiver.createMediator<FsoGps.SimSetServiceCenterNumber>();
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
        var m = receiver.createMediator<FsoGps.SimUnlock>();
        yield m.run( puk, new_pin );
    }

    public signal void auth_status( FreeSmartphone.GSM.SIMAuthStatus status);
    public signal void incoming_stored_message( int index);
    public signal void ready_status( bool status);

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

    public async string get_calling_identification( ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async void get_network_country_code( out string dial_code, out string country_name ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async int get_signal_strength() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async GLib.HashTable<string,GLib.Value?> get_status( ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        throw new FreeSmartphone.Error.INTERNAL_ERROR( "Not yet implemented" );
    }

    public async FreeSmartphone.GSM.NetworkProvider[] list_providers( ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = receiver.createMediator<FsoGps.NetworkListProviders>();
        yield m.run();
        return m.providers;
    }

    public async void register_() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var m = receiver.createMediator<FsoGps.NetworkRegister>();
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
    */
}

public class DBusService.Resource : FsoFramework.AbstractDBusResource
{
    public Resource( FsoFramework.Subsystem subsystem )
    {
        base( "GPS", subsystem );
    }

    public override async void enableResource()
    {
        logger.debug( "Enabling GPS resource..." );
        device.enable();
    }

    public override async void disableResource()
    {
        logger.debug( "Disabling GPS resource..." );
        device.disable();
    }

    public override async void suspendResource()
    {
        logger.debug( "Suspending GPS resource..." );
        device.suspend();
    }

    public override async void resumeResource()
    {
        logger.debug( "Resuming GPS resource..." );
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
    if ( DBusService.Device.receiverclass != Type.INVALID )
    {
        resource = new DBusService.Resource( subsystem );
    }
    return DBusService.MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    debug( "dbus_service fso_register_function" );
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
