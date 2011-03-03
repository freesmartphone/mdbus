/*
 * Copyright (C) 2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
using FsoGsm;
using GIsiComm;

namespace NokiaIsi
{

/**
 * @class IsiUnsolicited
 **/
public class IsiUnsolicitedHandler : FsoFramework.AbstractObject
{
    public IsiUnsolicitedHandler()
    {
        NokiaIsi.isimodem.net.signalStrength.connect( onSignalStrengthUpdate );
        NokiaIsi.isimodem.net.registrationStatus.connect( onRegistrationStatusUpdate );
    }

    public override string repr()
    {
        return "<>";
    }

    private void onSignalStrengthUpdate( uint8 rssi )
    {
        var obj = theModem.theDevice<FreeSmartphone.GSM.Network>();
        obj.signal_strength( rssi );
    }

    private void onRegistrationStatusUpdate( Network.ISI_RegStatus istatus )
    {
        switch ( istatus.status )
        {
            case GIsiClient.Network.RegistrationStatus.HOME:
            case GIsiClient.Network.RegistrationStatus.ROAM:
            case GIsiClient.Network.RegistrationStatus.ROAM_BLINK:
                theModem.advanceToState( FsoGsm.Modem.Status.ALIVE_REGISTERED );
                break;

            default:
                theModem.advanceToState( FsoGsm.Modem.Status.ALIVE_SIM_READY );
                break;
        }

        var obj = theModem.theDevice<FreeSmartphone.GSM.Network>();
        obj.status( isiRegStatusToFsoRegStatus( istatus ) );
    }
}

} /* namespace NokiaIsi */
