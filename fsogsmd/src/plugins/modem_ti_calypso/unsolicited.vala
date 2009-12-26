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
 */

using FsoGsm;
using Gee;

public class TiCalypso.UnsolicitedResponseHandler : FsoGsm.AtUnsolicitedResponseHandler
{
    private bool phbReady;
    private bool smsReady;

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

        /*
        def percentCSTAT( self, righthandside ):

        subsystem, available = safesplit( righthandside, "," )
        if not bool(int(available)): # not ready
            if subsystem in ( "PHB", "SMS" ):
                self.subsystemReadyness[subsystem] = False
                logger.info( "subsystem %s readyness now %s" % ( subsystem, self.subsystemReadyness[subsystem] ) )
                if not self.fullReadyness == False:
                    self._object.ReadyStatus( False )
                    self.fullReadyness = False
        else: # ready
            if subsystem in ( "PHB", "SMS" ):
                self.subsystemReadyness[subsystem] = True
                logger.info( "subsystem %s readyness now %s" % ( subsystem, self.subsystemReadyness[subsystem] ) )
                newFullReadyness = self.subsystemReadyness["PHB"] and self.subsystemReadyness["SMS"]
                if newFullReadyness and ( not self.fullReadyness == True ):
                    self._object.ReadyStatus( True )
                    self.fullReadyness = True

        logger.info( "full readyness now %s" % self.fullReadyness )
        */


        theModem.logger.info( "ti calypso sim ready" );
        theModem.advanceToState( FsoGsm.Modem.Status.ALIVE_SIM_READY );
    }

}
