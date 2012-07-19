/*
 * Copyright (C) 2009-2012 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
                modem.logger.info( "TI Calypso SIM now ready" );
                modem.advanceToState( FsoGsm.Modem.Status.ALIVE_SIM_READY );
            }
        }
    }

    public UnsolicitedResponseHandler( FsoGsm.Modem modem )
    {
        base( modem );

        registerUrc( "AT-Command Interpreter ready", channelReady );
        registerUrc( "%CPI", percentCPI );
        registerUrc( "%CPRI", percentCPRI );
        registerUrc( "%CSSN", percentCSSN );
        registerUrc( "%CSTAT", percentCSTAT );
        registerUrc( "%CSQ", percentCSQ );
    }

    public virtual void channelReady( string prefix, string rhs )
    {
        assert( modem.logger.debug( "Congratulations Madam, it's a channel!" ) );
    }

    public virtual void percentCPI( string prefix, string rhs )
    {
        switch ( rhs[2] )
        {
            case '0':
            case '9':
                var calypso = (TiCalypso.Modem) modem;
                var cmd = new CustomAtCommand();
                modem.processAtCommandAsync( cmd, calypso.dspCommand );
                break;
            default:
                break;
        }

    }

    public virtual void percentCPRI( string prefix, string rhs )
    {
        var cpri = modem.createAtCommand<PercentCPRI>( "%CPRI" );
        if ( cpri.validateUrc( @"$prefix: $rhs" ) == Constants.AtResponse.VALID )
        {
            // FIXME: Might want to remember the status
            var obj = modem.theDevice<FreeSmartphone.GSM.Network>();
            obj.cipher_status( (FreeSmartphone.GSM.CipherStatus) cpri.telcipher, (FreeSmartphone.GSM.CipherStatus) cpri.pdpcipher );
        }
    }

    public virtual void percentCSSN( string prefix, string rhs )
    {
        // FIXME: Implement
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
        var cstat = modem.createAtCommand<PercentCSTAT>( "%CSTAT" );
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

    public virtual void percentCSQ( string prefix, string rhs )
    {
        var csq = modem.createAtCommand<PercentCSQ>( "%CSQ" );
        if ( csq.validateUrc( @"$prefix: $rhs" ) == Constants.AtResponse.VALID )
        {
            // FIXME: Might want to remember the status
            var obj = modem.theDevice<FreeSmartphone.GSM.Network>();
            obj.signal_strength( csq.strength );
        }
    }
}

// vim:ts=4:sw=4:expandtab
