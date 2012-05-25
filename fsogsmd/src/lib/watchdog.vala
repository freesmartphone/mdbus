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
 **/

/**
 * @interface WatchDog
 **/
public interface FsoGsm.WatchDog : GLib.Object
{
    public abstract void check();
    public abstract void resetUnlockMarker();
}

/**
 * @class NullWatchDog
 **/

public class FsoGsm.NullWatchDog : GLib.Object, FsoGsm.WatchDog
{
    public void check()
    {
    }

    public void resetUnlockMarker()
    {
    }
}

/**
 * @class GenericWatchDog
 *
 **/
public class FsoGsm.GenericWatchDog : FsoGsm.WatchDog, FsoFramework.AbstractObject
{
    private bool unlockFailed;
    private Modem.Status lastStatus;
    private bool inCampNetwork = false;

    public override string repr()
    {
        return @"<>";
    }

    private void onModemStatusChange( Modem.Status status )
    {
        assert( logger.debug( @"onModemStatusChange $lastStatus -> $status" ) );
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

            case Modem.Status.ALIVE_REGISTERED:
                if ( lastStatus == Modem.Status.RESUMING )
                {
                    triggerUpdateNetworkStatus();
                }
                break;

            default:
                break;
        }

        lastStatus = status;
    }

    private async void unlockModem()
    {
        try
        {
            var m = theModem.createMediator<FsoGsm.SimSendAuthCode>();
            yield m.run( theModem.data().simPin );
        }
        catch ( GLib.Error e1 )
        {
            logger.error( @"Could not unlock SIM PIN: $(e1.message)" );
            unlockFailed = true;
            // resend query to give us a proper PIN
            try
            {
                yield gatherSimStatusAndUpdate();
            }
            catch ( GLib.Error e2 )
            {
                logger.error( @"Can't gather SIM status: $(e2.message)" );
            }
        }
    }

    private async void campNetwork()
    {
        if ( inCampNetwork )
            return;

        inCampNetwork = true;

        try
        {
            var m = theModem.createMediator<FsoGsm.NetworkRegister>();
            yield m.run();
        }
        catch ( GLib.Error e )
        {
            logger.error( @"Could not register: $(e.message)" );
        }

        triggerUpdateNetworkStatus();

        inCampNetwork = false;
    }

    //
    // public API
    //
    public GenericWatchDog()
    {
        lastStatus = theModem.status();
        theModem.signalStatusChanged.connect( onModemStatusChange );
    }

    public void check()
    {
        onModemStatusChange( theModem.status() );
    }

    public void resetUnlockMarker()
    {
        unlockFailed = false;
    }
}

// vim:ts=4:sw=4:expandtab
