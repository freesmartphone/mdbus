/*
 * Copyright (C) 2011 Klaus 'mrmoku' Kurzmann   <mok@fluxnetz.de>
 *               2011 Lukas 'slyon' Märdian     <lukasmaerdian@gmail.com>
 *               2012 Simon Busch               <morphis@gravedo.de>
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

namespace Gtm601
{
    public class AtCallSendDtmf : CallSendDtmf
    {
        public override async void run( string tones ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
        {
            var cmd = theModem.createAtCommand<PlusVTS>( "+VTS" );
            theModem.sendAtCommand( cmd, cmd.issue( tones ) );
        }
    }

    /**
     * Sadly the Option GTM601 modem does not return the provider names a real strings.
     * Instead it returns the hexadecimal representation of each character concatenated as
     * a long string. To handle this and provider the correct provider names we override
     * the common NetworkListProviders mediator here and implement the conversion routine.
     **/
    public class AtNetworkListProviders : NetworkListProviders
    {
        public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
        {
            var providers_tmp = new FreeSmartphone.GSM.NetworkProvider[] { };

            var cmd = theModem.createAtCommand<PlusCOPS>( "+COPS" );
            var response = yield theModem.processAtCommandAsync( cmd, cmd.test() );
            checkTestResponseValid( cmd, response );

            foreach ( var p in cmd.providers )
            {
                providers_tmp += FreeSmartphone.GSM.NetworkProvider(
                    p.status,
                    Codec.hexToString( p.shortname ),
                    Codec.hexToString( p.longname ),
                    p.mccmnc,
                    p.act );
            }

            providers = providers_tmp;
        }
    }

    public class AtSimGetServiceCenterNumber : SimGetServiceCenterNumber
    {
        public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
        {
            var cmd = theModem.createAtCommand<PlusCSCA>( "+CSCA" );
            var response = yield theModem.processAtCommandAsync( cmd, cmd.query() );
            checkResponseValid( cmd, response );
            number = Codec.hexToString( cmd.number );
        }
    }


    /* register all mediators */
    public void registerCustomMediators( HashMap<Type,Type> mediators )
    {
        mediators[ typeof(CallSendDtmf) ] = typeof( Gtm601.AtCallSendDtmf );
        mediators[ typeof(NetworkListProviders) ] = typeof( Gtm601.AtNetworkListProviders );
        mediators[ typeof(SimGetServiceCenterNumber) ] = typeof( Gtm601.AtSimGetServiceCenterNumber );
    }

} // namespace Gtm601

// vim:ts=4:sw=4:expandtab
