/*
 * (C) 2011 Simon Busch <morphis@gravedo.de>
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

public class FsoTest.TestGSM : FsoFramework.Test.TestCase
{
    private FreeSmartphone.Usage usage;
    private FreeSmartphone.GSM.Device gsm_device;
    private FreeSmartphone.GSM.Network gsm_network;
    private FreeSmartphone.GSM.SIM gsm_sim;
    private FreeSmartphone.GSM.Call gsm_call;
    private FreeSmartphone.GSM.PDP gsm_pdp;
    private FreeSmartphone.GSM.SMS gsm_sms;
    private FreeSmartphone.GSM.CB gsm_cb;
    private FreeSmartphone.GSM.VoiceMail gsm_voicemail;
    private string pin_from_config;

    public TestGSM()
    {
        base("FreeSmartphone.GSM");

        add_async_test( "RequestResource",
                        cb => test_request_gsm_resource( cb ),
                        res => test_request_gsm_resource.end( res ) );

        add_async_test( "ValidateInitialDeviceStatus",
                        cb => test_validate_initial_device_status( cb ),
                        res => test_validate_initial_device_status.end( res ) );

        add_async_test( "ValidateInitialSimAuthStatus",
                        cb => test_validate_initial_sim_auth_status( cb ),
                        res => test_validate_initial_sim_auth_status.end( res ) );

        add_async_test( "ValidateInitialNetworkStatus",
                        cb => test_validate_initial_network_status( cb ),
                        res => test_validate_initial_network_status.end( res ) );

        add_async_test( "ValidateInitialDeviceFunctionality",
                        cb => test_validate_initial_device_functionality( cb ),
                        res => test_validate_initial_device_functionality.end( res ) );

        add_async_test( "SetFullDeviceFunctionality",
                        cb => test_set_full_device_functionality( cb ),
                        res => test_set_full_device_functionality.end( res ) );

        add_async_test( "SetAirplaneDeviceFunctionality",
                        cb => test_set_airplane_device_functionality( cb ),
                        res => test_set_airplane_device_functionality.end( res ) );

        add_async_test( "RequestResource",
                        cb => test_release_gsm_resource( cb ),
                        res => test_release_gsm_resource.end( res ) );

        pin_from_config = theConfig.stringValue( "test-gsm", "pin", "1234" );

        try
        {
            usage = Bus.get_proxy_sync<FreeSmartphone.Usage>( BusType.SYSTEM, FsoFramework.Usage.ServiceDBusName,
                FsoFramework.Usage.ServicePathPrefix );

            gsm_device = Bus.get_proxy_sync<FreeSmartphone.GSM.Device>( BusType.SYSTEM, FsoFramework.GSM.ServiceDBusName,
                FsoFramework.GSM.DeviceServicePath );

            gsm_network = Bus.get_proxy_sync<FreeSmartphone.GSM.Network>( BusType.SYSTEM, FsoFramework.GSM.ServiceDBusName,
                FsoFramework.GSM.DeviceServicePath );

            gsm_sim = Bus.get_proxy_sync<FreeSmartphone.GSM.SIM>( BusType.SYSTEM, FsoFramework.GSM.ServiceDBusName,
                FsoFramework.GSM.DeviceServicePath );

            gsm_call = Bus.get_proxy_sync<FreeSmartphone.GSM.Call>( BusType.SYSTEM, FsoFramework.GSM.ServiceDBusName,
                FsoFramework.GSM.DeviceServicePath );

            gsm_pdp = Bus.get_proxy_sync<FreeSmartphone.GSM.PDP>( BusType.SYSTEM, FsoFramework.GSM.ServiceDBusName,
                FsoFramework.GSM.DeviceServicePath );

            gsm_sms = Bus.get_proxy_sync<FreeSmartphone.GSM.SMS>( BusType.SYSTEM, FsoFramework.GSM.ServiceDBusName,
                FsoFramework.GSM.DeviceServicePath );

            gsm_cb = Bus.get_proxy_sync<FreeSmartphone.GSM.CB>( BusType.SYSTEM, FsoFramework.GSM.ServiceDBusName,
                FsoFramework.GSM.DeviceServicePath );

            gsm_voicemail = Bus.get_proxy_sync<FreeSmartphone.GSM.VoiceMail>( BusType.SYSTEM, FsoFramework.GSM.ServiceDBusName,
                FsoFramework.GSM.DeviceServicePath );
        }
        catch ( GLib.Error err )
        {
            critical( @"Could not create proxy objects for GSM services: $(err.message)" );
        }
    }

    /**
     * Test GSM resource registration as very often the modem is initialized while the
     * user requests the resource. If the resource is still accessible after the request
     * the test is successfull.
     */
    public async void test_request_gsm_resource() throws GLib.Error, AssertError
    {
        string[] resources;

        resources = yield usage.list_resources();
        Assert.is_true( "GSM" in resources );

        yield usage.request_resource( "GSM" );

        resources = yield usage.list_resources();
        Assert.is_true( "GSM" in resources );
    }

    /**
     * Check the various status bits of the GSM service. All should be in a well definied
     * initial state. If state is not correct the cause is either wrong preconditions or
     * a real bug in the service implementation.
     */
    public async void test_validate_initial_device_status() throws GLib.Error, AssertError
    {
        var device_status = yield gsm_device.get_device_status();
        if ( device_status == FreeSmartphone.GSM.DeviceStatus.ALIVE_NO_SIM )
            Assert.fail( "No SIM is plugged into the device; can not continue" );
        else if ( device_status == FreeSmartphone.GSM.DeviceStatus.UNKNOWN )
            Assert.fail( "Can not continue as GSM device is in a unknown state" );
        else if ( device_status == FreeSmartphone.GSM.DeviceStatus.ALIVE_SIM_UNLOCKED ||
                  device_status == FreeSmartphone.GSM.DeviceStatus.ALIVE_REGISTERED )
            Assert.fail( "SIM card is already unlocked or modem registered to network" );
        else if ( device_status != FreeSmartphone.GSM.DeviceStatus.INITIALIZING &&
                  device_status != FreeSmartphone.GSM.DeviceStatus.ALIVE_SIM_LOCKED )
            Assert.fail( @"GSM device is in a unexpected state $device_status" );
    }

    public async void test_validate_initial_sim_auth_status() throws GLib.Error, AssertError
    {
        var sim_status = yield gsm_sim.get_auth_status();
        if ( sim_status != FreeSmartphone.GSM.SIMAuthStatus.PIN_REQUIRED &&
             sim_status != FreeSmartphone.GSM.SIMAuthStatus.PIN2_REQUIRED )
        {
            Assert.fail( @"SIM card has an unexpected state $sim_status" );
        }
    }

    public async void test_validate_initial_network_status() throws GLib.Error, AssertError
    {
        var network_status = yield gsm_network.get_status();
        // NOTE we're only checking for the following three entries as the spec defines
        // them as mandatory and all other are optional for the modem protocol
        // implementation.
        Assert.is_true( network_status.lookup( "mode" ) != null );
        Assert.is_true( network_status.lookup( "registration" ) != null );
        Assert.is_true( network_status.lookup( "act" ) != null );

        Assert.should_throw_async( cb => gsm_network.get_signal_strength( cb ),
                                   res => gsm_network.get_signal_strength.end( res ),
                                   FREESMARTPHONE_ERROR_DOMAIN );

        // FIXME This should be not available in this state too but is not; need to talk
        // to mickeyl about this.
        // Assert.should_throw_async( cb => gsm_network.list_providers( cb ),
        //                           res => gsm_network.list_providers.end( res ) );
    }

    public async void test_validate_initial_device_functionality() throws GLib.Error, AssertError
    {
        string level = "", pin = "";
        bool autoregister = false;

        yield gsm_device.get_functionality( out level, out autoregister, out pin );
        Assert.are_equal<string>( level, "minimal" );
        Assert.are_equal<bool>( autoregister, false );
        Assert.are_equal<string>( pin, "" );
    }

    public async void test_set_full_device_functionality() throws GLib.Error, AssertError
    {
        string level = "", pin = "";
        bool autoregister = false;

        yield gsm_device.set_functionality( "full", true, pin_from_config );
        Timeout.add_seconds( 3, () => { test_set_full_device_functionality.callback(); return false; } );
        yield;

        var device_status = yield gsm_device.get_device_status();
        Assert.are_equal<FreeSmartphone.GSM.DeviceStatus>( device_status, FreeSmartphone.GSM.DeviceStatus.ALIVE_REGISTERED );

        var sim_auth_status = yield gsm_sim.get_auth_status();
        Assert.are_equal<FreeSmartphone.GSM.SIMAuthStatus>( sim_auth_status, FreeSmartphone.GSM.SIMAuthStatus.READY );

        yield gsm_device.get_functionality( out level, out autoregister, out pin );
        Assert.are_equal<string>( level, "full" );
        Assert.are_equal<bool>( autoregister, true );
        Assert.are_equal<string>( pin, pin_from_config );
    }

    public async void test_validate_device_features() throws GLib.Error, AssertError
    {
        var features = yield gsm_device.get_features();
        Assert.is_true( features.lookup( "voice" ) != null, "Device does not mention voice feature" );
        Assert.is_true( features.lookup( "csd" ) != null, "Device does not mention csd feature" );
        Assert.is_true( features.lookup( "gsm" ) != null, "Device does not mention gsm feature" );
        Assert.is_true( features.lookup( "cdma" ) != null, "Device does not mention cdma feature" );
        Assert.is_true( features.lookup( "pdp" ) != null, "Device does not mention pdp feature" );
        Assert.is_true( features.lookup( "fax" ) != null, "Device does not mention fax feature" );
        Assert.is_true( features.lookup( "facilities" ) != null, "Device does not mention facilities feature" );
    }

    public async void test_set_airplane_device_functionality() throws GLib.Error, AssertError
    {
        string level = "", pin = "";
        bool autoregister = false;

        yield gsm_device.set_functionality( "airplane", false, "" );
        Timeout.add_seconds( 3, () => { test_set_airplane_device_functionality.callback(); return false; } );

        yield gsm_device.get_functionality( out level, out autoregister, out pin );
        Assert.are_equal<string>( level, "airplane" );
        // NOTE autoregister is only valid if level is "full"
        Assert.are_equal<string>( pin, pin_from_config );
    }

    public async void test_release_gsm_resource() throws GLib.Error, AssertError
    {
        yield usage.release_resource( "GSM" );
    }
}

public static int main( string[] args )
{
    GLib.Test.init( ref args );

    TestSuite root = TestSuite.get_root();
    root.add_suite( new FsoTest.TestGSM().get_suite() );

    GLib.Test.run();

    return 0;
}

// vim:ts=4:sw=4:expandtab
