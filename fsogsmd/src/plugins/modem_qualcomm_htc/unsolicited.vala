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

public class QualcommHtc.UnsolicitedResponseHandler : FsoGsm.AtUnsolicitedResponseHandler
{
    private bool phbReady;
    private bool fullReady;

    private void updateReadyness()
    {
        var newFullReady = phbReady;
        if ( newFullReady != fullReady )
        {
            fullReady = newFullReady;

            if ( fullReady )
            {
                theModem.logger.info( "qualcomm_htc sim ready" );
                theModem.advanceToState( FsoGsm.Modem.Status.ALIVE_SIM_READY );
            }
        }
    }

    public UnsolicitedResponseHandler()
    {
        registerUrc( "+PB_READY", plusPB_READY );
        registerUrc( "+HTCCTZV", plusHTCCTZV );

    }

    /**
     * Qualcomm HTC subsystem status report:
     *
     * +PB_READY
     *
     * Sent, after the reading the SIM phonebook into internal RAM
     **/
    public virtual void plusPB_READY( string prefix, string rhs )
    {
        phbReady = true;
        updateReadyness();
    }

    /**
     * Qualcomm HTC time report
     *
     * +HTCCTZV: "10/05/02,15:27:30+08,1"
     *
     */
    public virtual void plusHTCCTZV( string prefix, string rhs )
    {
        var htcctv = theModem.createAtCommand<PlusHTCCTZV>( "+HTCCTZV" );
        if ( htcctv.validateUrc( @"$prefix: $rhs" ) == Constants.AtResponse.VALID )
        {
            GLib.Time t = {};
            t.hour = htcctv.hour;
            t.minute = htcctv.minute;
            t.second = htcctv.second;
            t.day = htcctv.day;
            t.month = htcctv.month - 1;
            t.year = htcctv.year - 1900;

            var epoch = Linux.timegm( t );

            var data = theModem.data();
            data.networkTimeReport.setTimeAndZone( (int)epoch, htcctv.tzoffset );
        }
        else
        {
            logger.warning( @"Received invalid +HTCCTZV message $rhs. Please report" );
        }

    }
}
