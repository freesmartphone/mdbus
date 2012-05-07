/*
 * Copyright (C) 2011 Simon Busch <morphis@gravedo.de>
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
using Gee;
using FsoGsm;

/**
 * @class Samsung
 **/
class Samsung.Modem : FsoGsm.AbstractModem
{
    private const string MAIN_CHANNEL_NAME = "main";
    private const string RFS_CHANNEL_NAME = "rfs";

    construct
    {
    }

    public override string repr()
    {
        return @"<>";
    }

    protected override bool powerOn()
    {
        base.powerOn();
        return true;
    }

    protected override void powerOff()
    {
        base.powerOff();
    }

    protected override FsoGsm.UnsolicitedResponseHandler createUnsolicitedHandler()
    {
        // NOTE: we define our base unsolicited handler in our commandqueue,
        // as the base on is very AT command specific atm. Need to change
        // this somewhere in the future ...
        return (FsoGsm.UnsolicitedResponseHandler) null;
    }

    protected override FsoGsm.CallHandler createCallHandler()
    {
        return (FsoGsm.CallHandler) new Samsung.CallHandler();
    }

    protected override FsoGsm.SmsHandler createSmsHandler()
    {
        return (FsoGsm.SmsHandler) new Samsung.SmsHandler();
    }

    protected override FsoGsm.PhonebookHandler createPhonebookHandler()
    {
        return (FsoGsm.PhonebookHandler) null;
    }

    protected override void createChannels()
    {
        var fmt_transport = ( modem_transport_spec.type == "samsung" ) ?
            new FsoGsm.SamsungModemTransport( modem_transport_spec.name ) : modem_transport_spec.create();
        new Samsung.IpcChannel( MAIN_CHANNEL_NAME, fmt_transport );

        var rfs_modem_port = config.stringValue( "fsogsm.modem_samsung", "modem_rfs_access", "/dev/modem_rfs" );
        // FIXME evaluate rfs_modem_port the same way as the default modem access
        // configuration does.
        var rfs_transport = new FsoGsm.SamsungModemTransport( rfs_modem_port );
        new Samsung.RfsChannel( RFS_CHANNEL_NAME, rfs_transport );
    }

    protected override FsoGsm.Channel channelForCommand( FsoGsm.AtCommand command, string query )
    {
        return (FsoGsm.Channel) null;
    }

    protected override void registerCustomMediators( HashMap<Type,Type> mediators )
    {
        mediators.clear(); // we don't need the default AT mediators

        mediators[ typeof(SimGetAuthStatus) ]             = typeof( SamsungSimGetAuthStatus );
        mediators[ typeof(SimSendAuthCode) ]              = typeof( SamsungSimSendAuthCode );
        mediators[ typeof(SimGetInformation) ]            = typeof( SamsungSimGetInformation );

        mediators[ typeof(DeviceGetFeatures) ]            = typeof( SamsungDeviceGetFeatures );
        mediators[ typeof(DeviceGetInformation) ]         = typeof( SamsungDeviceGetInformation );
        mediators[ typeof(DeviceGetFunctionality) ]       = typeof( SamsungDeviceGetFunctionality );
        mediators[ typeof(DeviceGetPowerStatus) ]         = typeof( SamsungDeviceGetPowerStatus );
        mediators[ typeof(DeviceSetFunctionality) ]       = typeof( SamsungDeviceSetFunctionality );

        mediators[ typeof(NetworkRegister) ]              = typeof( SamsungNetworkRegister );
        mediators[ typeof(NetworkRegisterWithProvider) ]  = typeof( SamsungNetworkRegisterWithProvider );
        mediators[ typeof(NetworkUnregister) ]            = typeof( SamsungNetworkUnregister );
        mediators[ typeof(NetworkGetStatus) ]             = typeof( SamsungNetworkGetStatus );
        mediators[ typeof(NetworkGetSignalStrength) ]     = typeof( SamsungNetworkGetSignalStrength );
        mediators[ typeof(NetworkListProviders) ]         = typeof( SamsungNetworkListProviders );

        mediators[ typeof(PdpActivateContext) ]           = typeof( AtPdpActivateContext );
        mediators[ typeof(PdpDeactivateContext) ]         = typeof( AtPdpDeactivateContext );
        mediators[ typeof(PdpSetCredentials) ]            = typeof( SamsungPdpSetCredentials );
        mediators[ typeof(PdpGetCredentials) ]            = typeof( AtPdpGetCredentials );

        mediators[ typeof(CallActivate) ]                 = typeof( SamsungCallActivate );
        mediators[ typeof(CallHoldActive) ]               = typeof( SamsungCallHoldActive );
        mediators[ typeof(CallInitiate) ]                 = typeof( SamsungCallInitiate );
        mediators[ typeof(CallListCalls) ]                = typeof( SamsungCallListCalls );
        mediators[ typeof(CallReleaseAll) ]               = typeof( SamsungCallReleaseAll );
        mediators[ typeof(CallRelease) ]                  = typeof( SamsungCallRelease );
        mediators[ typeof(CallSendDtmf) ]                 = typeof( SamsungCallSendDtmf );

        mediators[ typeof(SmsRetrieveTextMessages) ]      = typeof( SamsungSmsRetrieveTextMessages );
        mediators[ typeof(SmsSendTextMessage) ]           = typeof( SamsungSmsSendTextMessage );
    }
}

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    FsoFramework.theLogger.debug( "samsung fso_factory_function" );
    return "fsogsm.modem_samsung";
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    // do not remove this function
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
