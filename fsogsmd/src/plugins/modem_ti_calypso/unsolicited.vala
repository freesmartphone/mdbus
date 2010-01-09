/**
 * Copyright (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

using FsoGsm;
using Gee;

public class TiCalypso.UnsolicitedResponseHandler : FsoGsm.AtUnsolicitedResponseHandler
{
    private bool phbReady;
    private bool smsReady;
    private bool fullReady;

    private void updateReadyness()
    {
        var newFullReady = phbReady && smsReady;
        if ( newFullReady != fullReady )
        {
            fullReady = newFullReady;

            if ( fullReady )
            {
                theModem.logger.info( "ti calypso sim ready" );
                theModem.advanceToState( FsoGsm.Modem.Status.ALIVE_SIM_READY );
            }
        }
    }

    public UnsolicitedResponseHandler()
    {
        registerUrc( "%CSTAT", percentCSTAT );
    }

    /**
     * TI Calypso subsystem status report:
     *
     * %CSTAT: PHB,0
     * %CSTAT: SMS,0
     * %CSTAT: RDY,1
     * %CSTAT: EONS,1
     *
     * PHB is phonebook, SMS is messagebook. RDY is supposed to be sent, after
     * PHB and SMS both being 1, however it's not sent on all devices.
     * EONS is completely undocumented, but likely the reading of the operator
     * table elementary files from the SIM. Not that it would matter anyways, since
     * these may be corrupt, hence this signal is very unreliable.
     *
     * Due to RDY being unreliable as well, we wait for PHB and SMS sending availability
     * and then synthesize a global SimReady signal.
     **/
    public virtual void percentCSTAT( string prefix, string rhs )
    {
        var cstat = theModem.createAtCommand<PercentCSTAT>( "%CSTAT" );
        if ( cstat.validateUrc( @"$prefix: $rhs" ) == Constants.AtResponse.VALID )
        {
            switch ( cstat.subsystem )
            {
                case "PHB":
                    phbReady = cstat.ready;
                    updateReadyness();
                    break;
                case "SMS":
                    smsReady = cstat.ready;
                    updateReadyness();
                    break;
                default:
                    break;
            }
        }
    }
}
