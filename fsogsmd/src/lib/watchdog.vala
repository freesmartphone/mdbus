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
 **/

/**
 * @interface WatchDog
 **/
public interface FsoGsm.WatchDog : GLib.Object
{
}

/**
 * @class GenericWatchDog
 **/
public class FsoGsm.GenericWatchDog : FsoGsm.WatchDog, FsoFramework.AbstractObject
{
    private bool unlockFailed;

    public GenericWatchDog()
    {
        theModem.signalStatusChanged.connect( onModemStatusChange );
    }

    public override string repr()
    {
        return "<>";
    }

    private void onModemStatusChange( Modem.Status status )
    {
        var data = theModem.data();

        switch ( status )
        {
            case Modem.Status.ALIVE_SIM_LOCKED:
                if ( data.simAuthStatus == FreeSmartphone.GSM.SIMAuthStatus.PIN_REQUIRED &&
                     data.simPin != "" &&
                     !unlockFailed )
                {
                    unlockModem();
                }
                break;

            case Modem.Status.ALIVE_SIM_READY:
                if ( theModem.data().keepRegistration )
                {
                    campNetwork();
                }
                break;

            default:
                break;
        }
    }

    private async void unlockModem()
    {
        try
        {
            var m = theModem.createMediator<FsoGsm.SimSendAuthCode>();
            yield m.run( theModem.data().simPin );
        }
        catch ( FreeSmartphone.GSM.Error e )
        {
            logger.error( @"Could not unlock SIM PIN: $(e.message)" );
            unlockFailed = true;
        }
    }

    private async void campNetwork()
    {
        try
        {
            var m = theModem.createMediator<FsoGsm.NetworkRegister>();
            yield m.run();
        }
        catch ( FreeSmartphone.GSM.Error e )
        {
            logger.error( @"Could not register: $(e.message)" );
        }
    }
}
