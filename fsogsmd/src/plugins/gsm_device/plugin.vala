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
    public async bool get_antenna_power() throws DBus.Error
    {
        Type t = modem.mediatorFactory( "DeviceGetAntennaPower" );
        FsoGsm.DeviceGetAntennaPower m = Object.new( t ) as FsoGsm.DeviceGetAntennaPower;
        yield m.run();
        return m.antenna_power;
    }

    public async GLib.HashTable<string,GLib.Value?> get_info() throws DBus.Error
    {
        Type t = modem.mediatorFactory( "DeviceGetInformation" );
        FsoGsm.DeviceGetInformation m = Object.new( t ) as FsoGsm.DeviceGetInformation;
        yield m.run();
        return m.info;
    }

    public async GLib.HashTable<string,GLib.Value?> get_features() throws DBus.Error
    {
        var r = new GLib.HashTable<string,GLib.Value?>( str_hash, str_equal );
        return r;
    }

    public async bool get_microphone_muted() throws DBus.Error
    {
        return false;
    }

    public async bool get_sim_buffers_sms() throws DBus.Error
    {
        return false;
    }

    public async int get_speaker_volume() throws DBus.Error
    {
        return 0;
    }

    public async void set_antenna_power(bool antenna_power) throws DBus.Error
    {
    }

    public async void set_microphone_muted(bool muted) throws DBus.Error
    {
    }

    public async void set_sim_buffers_sms(bool sim_buffers_sms) throws DBus.Error
    {
    }

    public async void set_speaker_volume(int volume) throws DBus.Error
    {
    }

    public async void get_power_status(out string status, out int level) throws DBus.Error
    {
        status = "";
        level = 0;
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
