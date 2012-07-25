/*
 * (C) 2011-2012 Simon Busch <morphis@gravedo.de>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 */

using GLib;
using FsoFramework;
using FsoFramework.Test;

namespace FsoTest
{
    public const string FREESMARTPHONE_ERROR_DOMAIN = "free_smartphone_error-quark";
}

public abstract class FsoTest.GsmBaseTest : FsoFramework.Test.TestCase
{
    private IProcessGuard fsogsmd_process;
    private IProcessGuard phonesim_process;

    protected IRemotePhoneControl remote_control { get; private set; }
    protected FreeSmartphone.GSM.Device gsm_device;
    protected FreeSmartphone.GSM.Network gsm_network;
    protected FreeSmartphone.GSM.SIM gsm_sim;
    protected FreeSmartphone.GSM.Call gsm_call;
    protected FreeSmartphone.GSM.PDP gsm_pdp;
    protected FreeSmartphone.GSM.SMS gsm_sms;
    protected FreeSmartphone.GSM.CB gsm_cb;
    protected FreeSmartphone.GSM.VoiceMail gsm_voicemail;

    protected struct Configuration
    {
        public string pin;
        public int default_timeout;
        public bool remote_enabled;
        public string remote_type;
        public string remote_number0;
        public string remote_number1;
    }

    protected Configuration config;

    //
    // private
    //

    private bool start_daemon()
    {
        // FIXME check wether one of both processes is already running

        fsogsmd_process = new GProcessGuard();
        phonesim_process = new GProcessGuard();

        // FIXME prefix with directory where the phonesim configuration is stored
        if ( !phonesim_process.launch( new string[] { "phonesim", "-p", "3001", "-gui", "phonesim-default.xml" } ) )
            return false;

        Posix.sleep( 3 );

        if ( !fsogsmd_process.launch( new string[] { "fsogsmd", "--test" } ) )
            return false;

        Posix.sleep( 3 );

        return true;
    }

    private void stop_daemon()
    {
        GLib.Log.set_always_fatal( GLib.LogLevelFlags.LEVEL_CRITICAL );
        fsogsmd_process.stop();
        phonesim_process.stop();
    }

    //
    // protected
    //

    protected GsmBaseTest( string name )
    {
        base( name );

        config.default_timeout = theConfig.intValue( "default", "timeout", 60000 );
        config.pin = theConfig.stringValue( "default", "pin", "1234" );
        config.remote_enabled = theConfig.boolValue( "remote_control", "enabled", true );
        config.remote_type = theConfig.stringValue( "remote_control", "type", "phonesim" );
        config.remote_number0 = theConfig.stringValue( "remote_control", "number0", "+491234567890" );
        config.remote_number1 = theConfig.stringValue( "remote_control", "number1", "+499876543210" );

        remote_control = new PhonesimRemotePhoneControl();
        start_daemon();

        try
        {
            gsm_device = Bus.get_proxy_sync<FreeSmartphone.GSM.Device>( BusType.SESSION, FsoFramework.GSM.ServiceDBusName,
                FsoFramework.GSM.DeviceServicePath, DBusProxyFlags.DO_NOT_AUTO_START );

            gsm_network = Bus.get_proxy_sync<FreeSmartphone.GSM.Network>( BusType.SESSION, FsoFramework.GSM.ServiceDBusName,
                FsoFramework.GSM.DeviceServicePath, DBusProxyFlags.DO_NOT_AUTO_START );

            gsm_sim = Bus.get_proxy_sync<FreeSmartphone.GSM.SIM>( BusType.SESSION, FsoFramework.GSM.ServiceDBusName,
                FsoFramework.GSM.DeviceServicePath, DBusProxyFlags.DO_NOT_AUTO_START );

            gsm_call = Bus.get_proxy_sync<FreeSmartphone.GSM.Call>( BusType.SESSION, FsoFramework.GSM.ServiceDBusName,
                FsoFramework.GSM.DeviceServicePath, DBusProxyFlags.DO_NOT_AUTO_START );

            gsm_pdp = Bus.get_proxy_sync<FreeSmartphone.GSM.PDP>( BusType.SESSION, FsoFramework.GSM.ServiceDBusName,
                FsoFramework.GSM.DeviceServicePath, DBusProxyFlags.DO_NOT_AUTO_START );

            gsm_sms = Bus.get_proxy_sync<FreeSmartphone.GSM.SMS>( BusType.SESSION, FsoFramework.GSM.ServiceDBusName,
                FsoFramework.GSM.DeviceServicePath, DBusProxyFlags.DO_NOT_AUTO_START );

            gsm_cb = Bus.get_proxy_sync<FreeSmartphone.GSM.CB>( BusType.SESSION, FsoFramework.GSM.ServiceDBusName,
                FsoFramework.GSM.DeviceServicePath, DBusProxyFlags.DO_NOT_AUTO_START );

            gsm_voicemail = Bus.get_proxy_sync<FreeSmartphone.GSM.VoiceMail>( BusType.SESSION, FsoFramework.GSM.ServiceDBusName,
                FsoFramework.GSM.DeviceServicePath, DBusProxyFlags.DO_NOT_AUTO_START );
        }
        catch ( GLib.Error err )
        {
            critical( @"Could not create proxy objects for GSM services: $(err.message)" );
        }

    }

    protected async void ensure_sim_authenticated() throws GLib.Error, AssertError
    {
        var sim_auth_status = yield gsm_sim.get_auth_status();
        if ( sim_auth_status != FreeSmartphone.GSM.SIMAuthStatus.READY )
        {
            yield gsm_sim.send_auth_code( config.pin );
            yield asyncWaitSeconds( 1 );
            sim_auth_status = yield gsm_sim.get_auth_status();
            Assert.is_true( sim_auth_status == FreeSmartphone.GSM.SIMAuthStatus.READY );
        }
    }

    protected async void ensure_full_functionality() throws GLib.Error, AssertError
    {
        var device_status = yield gsm_device.get_device_status();

        if ( device_status != FreeSmartphone.GSM.DeviceStatus.ALIVE_REGISTERED )
        {
            yield gsm_device.set_functionality( "full", true, config.pin );
            yield asyncWaitSeconds( 3 );
            device_status = yield gsm_device.get_device_status();
            Assert.is_true( device_status == FreeSmartphone.GSM.DeviceStatus.ALIVE_REGISTERED );
        }
    }

    //
    // public
    //

    public void shutdown()
    {
        stop_daemon();
    }
}

// vim:ts=4:sw=4:expandtab
