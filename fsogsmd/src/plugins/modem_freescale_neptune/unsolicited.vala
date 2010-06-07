/*
 * Copyright (C) 2010  Antonio Ospite <ospite@studenti.unina.it>
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
 */

using Gee;
using FsoGsm;

public class FreescaleNeptune.UnsolicitedResponseHandler : FsoGsm.AtUnsolicitedResponseHandler
{
    public UnsolicitedResponseHandler()
    {
        registerUrc( "+MBAN", channelReady );
        registerUrc( "+CIEV", plusCIEV );
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
     *  7: roaming (0-2)
     *  8: sms storage full (0-1)
     * 11: ???
     * 20: ??? (SIM not inserted?)
     **/
    public override void plusCIEV( string prefix, string rhs )
    {
        int indicator = rhs.split(",")[0].to_int();
        int value = rhs.split(",")[1].to_int();

        switch (indicator) {
        case 1:
            theModem.logger.debug( @"plusCIEV: $indicator,$value NOT implemented" );
            break;
        case 2:
            theModem.logger.debug( @"plusCIEV: $indicator,$value NOT implemented" );
            break;
        case 3:
            theModem.logger.debug( @"plusCIEV: $indicator,$value NOT implemented" );
            break;
        case 4:
            theModem.logger.debug( @"plusCIEV: $indicator,$value NOT implemented" );
            break;
        case 5:
            theModem.logger.debug( @"plusCIEV: $indicator,$value NOT implemented" );
            break;
        case 6:
            theModem.logger.debug( @"plusCIEV: $indicator,$value NOT implemented" );
            break;
        case 7:
            theModem.logger.debug( @"plusCIEV: $indicator,$value NOT implemented" );
            break;
        case 8:
            theModem.logger.debug( @"plusCIEV: $indicator,$value NOT implemented" );
            break;
        case 11:
            theModem.logger.debug( @"plusCIEV: $indicator,$value NOT implemented" );
            break;
        case 20:
            theModem.logger.debug( @"plusCIEV: $indicator,$value NOT implemented" );
            break;
        default:
            theModem.logger.warning( @"plusCIEV: $indicator,$value UNKNOWN" );
            break;
        }
    }

    /**
     * When an incoming call arrives we get the URC:
     * +CLIN: 0
     **/
    public void plusCLIN( string prefix, string rhs )
    {
            theModem.callhandler.handleIncomingCall("VOICE");
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
