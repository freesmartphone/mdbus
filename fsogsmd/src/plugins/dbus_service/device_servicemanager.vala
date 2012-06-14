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

public class FsoGsm.DeviceServiceManager : FsoGsm.ServiceManager
{
    private FsoGsm.Modem modem;

    public bool initialized { get; private set; default = false; }

    //
    // private
    //

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

    //
    // public API
    //

    public DeviceServiceManager( FsoGsm.Modem modem, FsoFramework.Subsystem subsystem )
    {
        base( subsystem, FsoFramework.GSM.ServiceDBusName, FsoFramework.GSM.DeviceServicePath );

        base.registerService<FreeSmartphone.Info>( new FsoGsm.InfoService() );
        base.registerService<FreeSmartphone.Device.RealtimeClock>( new FsoGsm.DeviceRtcService() );
        base.registerService<FreeSmartphone.Device.PowerSupply>( new FsoGsm.DevicePowerSupplyService() );
        base.registerService<FreeSmartphone.GSM.Device>( new FsoGsm.GsmDeviceService() );
        base.registerService<FreeSmartphone.GSM.Debug>( new FsoGsm.GsmDebugService() );
        base.registerService<FreeSmartphone.GSM.Call>(new FsoGsm.GsmCallService() );
        base.registerService<FreeSmartphone.GSM.CallForwarding>( new FsoGsm.GsmCallForwardingService() );
        base.registerService<FreeSmartphone.GSM.CB>( new FsoGsm.GsmCbService() );
        base.registerService<FreeSmartphone.GSM.HZ>( new FsoGsm.GsmHzService() );
        base.registerService<FreeSmartphone.GSM.Monitor>( new FsoGsm.GsmMonitorService() );
        base.registerService<FreeSmartphone.GSM.Network>( new FsoGsm.GsmNetworkService() );
        base.registerService<FreeSmartphone.GSM.PDP>( new FsoGsm.GsmPdpService() );
        base.registerService<FreeSmartphone.GSM.SIM>( new FsoGsm.GsmSimService() );
        base.registerService<FreeSmartphone.GSM.SMS>( new FsoGsm.GsmSmsService() );
        base.registerService<FreeSmartphone.GSM.VoiceMail>( new FsoGsm.GsmVoiceMailService() );

        modem.parent = this;
        modem.hangup.connect( onModemHangup );
        this.assignModem( modem );

        initialized = true;

        logger.info( @"Ready. Configured for modem !!! FIXME !!!" );
    }

    public override async bool enable()
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

    public override async void disable()
    {
        yield modem.close();
        logger.info( "Modem closed successfully" );
    }

    public override async void suspend()
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

    public override async void resume()
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
}

// vim:ts=4:sw=4:expandtab
