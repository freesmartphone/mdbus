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

namespace FsoGsm
{
    private static bool inTriggerUpdateNetworkStatus;

    /**
     * Advance modem state based on current network registration status. If the modem is
     * not connected to any network we will fallback into ALIVE_SIM_READY and advance to
     * ALIVE_REGISTERED otherwise. This needs the NetworkGetStatus mediator to be
     * implemented.
     **/
    public async void triggerUpdateNetworkStatus( FsoGsm.Modem  modem )
    {
        if ( inTriggerUpdateNetworkStatus )
        {
            assert( modem.logger.debug( "already gathering network status... ignoring additional trigger" ) );
            return;
        }
        inTriggerUpdateNetworkStatus = true;

        var mstat = modem.status();

        // ignore, if we don't have proper status to issue networking commands yet
        if ( mstat != Modem.Status.ALIVE_SIM_READY && mstat != Modem.Status.ALIVE_REGISTERED )
        {
            assert( modem.logger.debug( @"triggerUpdateNetworkStatus() ignored while modem is in status $mstat" ) );
            inTriggerUpdateNetworkStatus = false;
            return;
        }

        try
        {
            var m = modem.createMediator<FsoGsm.NetworkGetStatus>();
            yield m.run();

            // advance modem status, if necessary
            var status = m.status.lookup( "registration" ).get_string();
            assert( modem.logger.debug( @"triggerUpdateNetworkStatus() status = $status" ) );

            switch ( status )
            {
                case "home":
                case "roaming":
                    modem.advanceToState( Modem.Status.ALIVE_REGISTERED );
                    modem.advanceNetworkState( Modem.NetworkStatus.REGISTERED );
                    break;
                case "searching":
                    modem.advanceToState( Modem.Status.ALIVE_SIM_READY, true );
                    modem.advanceNetworkState( Modem.NetworkStatus.SEARCHING );
                    break;
                case "denied":
                case "unregistered":
                case "unknown":
                    modem.advanceToState( Modem.Status.ALIVE_SIM_READY, true );
                    modem.advanceNetworkState( Modem.NetworkStatus.UNREGISTERED );
                    break;
            }

            // send dbus signal
            var obj = modem.theDevice<FreeSmartphone.GSM.Network>();
            obj.status( m.status );
        }
        catch ( GLib.Error e )
        {
            modem.logger.warning( @"Can't query networking status: $(e.message)" );
            inTriggerUpdateNetworkStatus = false;
            return;
        }

        inTriggerUpdateNetworkStatus = false;
    }

    /**
     * Validate wether a phone number consists only of valid characters and as a correct
     * prefix (aka +0*). A INVALID_PARAMETER exception will be thrown if the phone number
     * is invalid.
     **/
    public void validatePhoneNumber( string number ) throws FreeSmartphone.Error
    {
        if ( number == "" )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Number too short" );
        }

        for ( var i = ( number[0] == '+' ? 1 : 0 ); i < number.length; ++i )
        {
            if (number[i] >= '0' && number[i] <= '9')
                    continue;

            if (number[i] == '*' || number[i] == '#')
                    continue;

            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Number contains invalid character '%c' at position %u", number[i], i );
        }
    }

    public void validateDtmfTones( string tones ) throws FreeSmartphone.Error
    {
        if ( tones == "" )
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Invalid DTMF tones" );

        for ( var n = 0; n < tones.length; n++ )
        {
            var c = tones[n];
            if ( !c.isdigit() && c != 'p' && c !=  'P' && c != '*' && c != '#' && ( c < 'A' || c > 'D' ) )
            {
                throw new FreeSmartphone.Error.INVALID_PARAMETER( "Invalid DTMF tones" );
            }
        }
    }

    public async string findProviderNameForMccMnc( string mccmnc )
    {
        string provider = "unknown";

        try
        {
            var world_service = Bus.get_proxy_sync<FreeSmartphone.Data.World>( BusType.SYSTEM,
                FsoFramework.Data.WorldServicePath, FsoFramework.Data.WorldServiceFace );

            provider = yield world_service.get_provider_name_for_mcc_mnc( mccmnc );
        }
        catch ( GLib.Error err )
        {
            FsoFramework.theLogger.warning( @"Could not find and valid provider name for MCC/MNC $mccmnc" );
        }

        return provider;
    }

    public async void updateNetworkSignalStrength( FsoGsm.Modem modem, int strength )
    {
        if ( modem.status() == FsoGsm.Modem.Status.ALIVE_REGISTERED )
        {
            var obj = modem.theDevice<FreeSmartphone.GSM.Network>();
            obj.signal_strength( strength );
        }
        else
        {
            assert( FsoFramework.theLogger.debug( @"Ignoring signal strength update while not in ALIVE_REGISTERED state" ) );
        }
    }
}

// vim:ts=4:sw=4:expandtab
