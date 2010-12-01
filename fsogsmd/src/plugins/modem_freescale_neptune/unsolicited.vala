/*
 * Copyright (C) 2010  Antonio Ospite <ospite@studenti.unina.it>
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

using Gee;
using FsoGsm;

public class FreescaleNeptune.UnsolicitedResponseHandler : FsoGsm.AtUnsolicitedResponseHandler
{
    public UnsolicitedResponseHandler()
    {
        registerUrc( "+MBAN", channelReady );
        registerUrc( "+CLIN", plusCLIN );
        registerUrc( "+CLIP", plusCLIP );
        registerUrc( "+EBAD", dummy );
        registerUrc( "+EFLEX", dummy );
        registerUrc( "+EBPV", dummy );
    }

    public virtual void channelReady( string prefix, string rhs )
    {
        assert( theModem.logger.debug( "Congratulations Madam, it's a channel!" ) );
    }

    /**
     * Indicator Event Reporting. Based on 3GPP TS 07.07, Chapter 8.9, but slightly extended.
     *
     * As +CIND=? gives us a hint (one of the few test commands EZX exposes), we conclude:
     *
     *  0: battery charge level (0-5)
     *  1: signal level (0-5)
     *  2: service availability (0-1)
     *  3: call active? (0-1)
     *  4: voice mail (message) (0-1)
     *  5: transmit activated by voice activity (0-1)
     *  6: call progress (0-3) [0:no more in progress, 1:incoming, 2:outgoing, 3:ringing]
     *  7: roaming (0-2) [0:local, 1:home roaming, 2:overseas roaming]
     *  8: sms storage full (0-1)
     * 11: gprs context attachment (0-2) [0:detach, 1:attach, 2:combined attach]
     * 12: gprs service availability (0-1)
     * 13: gprs automatic attach availability (0-1)
     * 14: gprs status (0-1)
     * 15: gprs display status (0-1) [0:display, 1:do not display]
     * 18: power on mode (0-1)
     * 19: EONS status (0-1)
     * 20: EGPRS possible (0-1)
     * 21: EGPRS in use (0-1)
     **/
    public override void plusCIEV( string prefix, string rhs )
    {
        var ciev = theModem.createAtCommand<PlusCIEV>( "+CIEV" );
        if ( ! ( ciev.validateUrc( @"$prefix: $rhs" ) == Constants.AtResponse.VALID ) )
        {
            logger.warning( @"Received invalid +CIEV message $rhs. Please report" );
            return;
        }

        switch ( ciev.value1 ) /* indicator */
        {
            case 1:
                // FIXME: Might want to remember the status
                var obj = theModem.theDevice<FreeSmartphone.GSM.Network>();
                obj.signal_strength( Constants.instance().networkSignalIndicatorToPercentage( ciev.value2 ) );
                break;
            default:
                theModem.logger.warning( @"plusCIEV: $(ciev.value1),$(ciev.value2) unknown or not implemented" );
                break;
        }
    }

    /**
     * When an incoming call arrives we get the URC:
     * +CLIN: 0
     **/
    public void plusCLIN( string prefix, string rhs )
    {
        theModem.callhandler.handleIncomingCall( new FsoGsm.CallInfo.with_ctype( "VOICE" ) );
    }

    /**
     * +CLIP: "+4969123456789",145
     **/
    public override void plusCLIP( string prefix, string rhs )
    {
        assert( theModem.logger.debug( @"plusCLIP: not implemented on Neptune" ) );
    }

    public virtual void dummy( string prefix, string rhs )
    {
        assert( theModem.logger.debug( @"URC: $prefix not implemented on Neptune" ) );
    }
}
