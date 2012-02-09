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
    public async void triggerUpdateNetworkStatus()
    {
        if ( inTriggerUpdateNetworkStatus )
        {
            assert( theModem.logger.debug( "already gathering network status... ignoring additional trigger" ) );
            return;
        }
        inTriggerUpdateNetworkStatus = true;

        var mstat = theModem.status();

        // ignore, if we don't have proper status to issue networking commands yet
        if ( mstat != Modem.Status.ALIVE_SIM_READY && mstat != Modem.Status.ALIVE_REGISTERED )
        {
            assert( theModem.logger.debug( @"triggerUpdateNetworkStatus() ignored while modem is in status $mstat" ) );
            inTriggerUpdateNetworkStatus = false;
            return;
        }

        // gather info
        var m = theModem.createMediator<FsoGsm.NetworkGetStatus>();
        try
        {
            yield m.run();
        }
        catch ( GLib.Error e )
        {
            theModem.logger.warning( @"Can't query networking status: $(e.message)" );
            inTriggerUpdateNetworkStatus = false;
            return;
        }

        // advance modem status, if necessary
        var status = m.status.lookup( "registration" ).get_string();
        assert( theModem.logger.debug( @"triggerUpdateNetworkStatus() status = $status" ) );

        if ( status == "home" || status == "roaming" )
        {
            theModem.advanceToState( Modem.Status.ALIVE_REGISTERED );
        }
        else
        {
            theModem.advanceToState( Modem.Status.ALIVE_SIM_READY, true );
        }

        // send dbus signal
        var obj = theModem.theDevice<FreeSmartphone.GSM.Network>();
        obj.status( m.status );

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
}

// vim:ts=4:sw=4:expandtab
