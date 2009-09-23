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

namespace GsmDevice { const string MODULE_NAME = "fsogsm.gsm_device"; }

class GsmDevice.Device :
    FreeSmartphone.GSM.Device,
    FreeSmartphone.GSM.Network,
    FsoFramework.AbstractObject
{
    FsoFramework.Subsystem subsystem;
    static FsoGsm.Modem modem;

    static FsoGsm.Modem theModem()
    {
        return modem;
    }

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
            case "qualcomm_msm":
                typename = "QualcommMsmModem";
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

        var modemclass = Type.from_name( typename );
        if ( modemclass == Type.INVALID  )
        {
            logger.warning( "Can't find modem for modem_type = '%s'".printf( modemtype ) );
            return;
        }

        // FIXME use resource handling
        Idle.add( onInitFromMainloop );

        subsystem.registerServiceName( FsoFramework.GSM.ServiceDBusName );
        subsystem.registerServiceObject( FsoFramework.GSM.ServiceDBusName, FsoFramework.GSM.DeviceServicePath, this );

        modem = (FsoGsm.Modem) Object.new( modemclass );
        // modem knows about mediator factory
        logger.info( "Ready. Using modem '%s'".printf( modemtype ) );
    }

    public override string repr()
    {
        return "<GsmDevice>";
    }

    public bool onInitFromMainloop()
    {
        if ( !modem.open() )
            logger.error( "Can't open modem" );
        else
            logger.info( "Modem opened successfully" );
        return false; // don't call me again
    }

    //
    // DBUS
    //
    public async bool get_antenna_power() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        Type t = modem.mediatorFactory( typeof(FsoGsm.DeviceGetAntennaPower) );
        FsoGsm.DeviceGetAntennaPower m = Object.new( t ) as FsoGsm.DeviceGetAntennaPower;

        //FsoGsm.DeviceGetAntennaPower m = modem.createMediator<FsoGsm.DeviceGetAntennaPower>();
        yield m.run();
        return m.antenna_power;
    }

    public async GLib.HashTable<string,GLib.Value?> get_info() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        Type t = modem.mediatorFactory( typeof(FsoGsm.DeviceGetInformation) );
        assert( t == typeof(FsoGsm.AtDeviceGetInformation) );
        FsoGsm.DeviceGetInformation m = (FsoGsm.DeviceGetInformation) (Object.new( t ));

        //FsoGsm.DeviceGetInformation m = modem.createMediator<FsoGsm.DeviceGetInformation>;
        //FsoGsm.DeviceGetInformation m = modem.mediatorFactory( FsoGsm.DeviceGetInformation );
        yield m.run();
        return m.info;
    }

    public async GLib.HashTable<string,GLib.Value?> get_features() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var r = new GLib.HashTable<string,GLib.Value?>( str_hash, str_equal );
        return r;
    }

    public async bool get_microphone_muted() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        return false;
    }

    public async bool get_sim_buffers_sms() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        return false;
    }

    public async int get_speaker_volume() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        return 0;
    }

    public async void set_antenna_power( bool antenna_power ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
    }

    public async void set_microphone_muted( bool muted ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
    }

    public async void set_sim_buffers_sms( bool sim_buffers_sms ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
    }

    public async void set_speaker_volume( int volume ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
    }

    public async void get_power_status( out string status, out int level ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        status = "";
        level = 0;
    }

    //
    // DBUS(org.freesmartphone.GSM.Network.*)
    //
    public async void disable_call_forwarding( string reason, string class_ ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
    }

    public async void enable_call_forwarding( string reason, string class_, string number, int timeout ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
    }

    public async GLib.HashTable<string,GLib.Value?> get_call_forwarding( string reason ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var res = new GLib.HashTable<string,GLib.Value?>( str_hash, str_equal );
        return res;
    }

    public async string get_calling_identification( ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        return "unknown";
    }

    public async void get_network_country_code( out string dial_code, out string country_name ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        dial_code = "unknown";
        country_name = "unknown";
    }

    public async int get_signal_strength( ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        return 0;
    }

    public async GLib.HashTable<string,GLib.Value?> get_status( ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var res = new GLib.HashTable<string,GLib.Value?>( str_hash, str_equal );
        return res;
    }

    public async FreeSmartphone.GSM.NetworkProvider[] list_providers( ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        Type t = modem.mediatorFactory( typeof(FsoGsm.NetworkListProviders ) );
        FsoGsm.NetworkListProviders m = Object.new( t  ) as FsoGsm.NetworkListProviders;
        yield m.run();
        return m.providers;
    }

    public async void register_( ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
    }

    public async void register_with_provider( string operator_code ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
    }

    public async void send_ussd_request( string request ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
    }

    public async void set_calling_identification( string visible ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
    }

    public async void unregister( ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
    }
}

List<GsmDevice.Device> instances;

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    instances.append( new GsmDevice.Device( subsystem ) );
    return GsmDevice.MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    debug( "gsm_device fso_register_function" );
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
