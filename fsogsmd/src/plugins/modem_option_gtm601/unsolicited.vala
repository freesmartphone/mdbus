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

using FsoGsm;
using Gee;

public class Gtm601.UnsolicitedResponseHandler : FsoGsm.AtUnsolicitedResponseHandler
{
    public UnsolicitedResponseHandler( FsoGsm.Modem modem )
    {
        base( modem );

        registerUrc( "$QCSIMSTAT", dollarQCSIMSTAT );
        registerUrc( "_OSIGQ", underscoreOSIGQ );
    }

    /**
     * GTM SIM status report: "$QCSIMSTAT: 1, SIM INIT COMPLETED"
     **/
    public virtual void dollarQCSIMSTAT( string prefix, string rhs )
    {
        if ( rhs.has_suffix( "SIM INIT COMPLETED" ) )
        {
            modem.logger.info( "GTM 601 SIM now ready" );
            Timeout.add_seconds( 2, () => {
                modem.advanceToState( FsoGsm.Modem.Status.ALIVE_SIM_READY );
                return false; // don't call again
            } );
        }
    }

    /**
     * GTM network signal strength report: "_OSIGQ: 8,0"
     **/
    public virtual void underscoreOSIGQ( string prefix, string rhs )
    {
        var cmd = modem.createAtCommand<UnderscoreOSIGQ>( "_OSIGQ" );
        if ( cmd.validateUrc( @"$prefix: $rhs" ) == Constants.AtResponse.VALID )
        {
            var strength = Constants.networkSignalToPercentage( cmd.strength );
            updateNetworkSignalStrength( modem, strength );
        }
        else
        {
            logger.warning( @"Received invalid _OSIGQ message $rhs. Please report" );
        }
    }
}

// vim:ts=4:sw=4:expandtab
