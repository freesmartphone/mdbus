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

    /* register all mediators */
    public void registerCustomMediators( HashMap<Type,Type> mediators )
    {
        mediators[ typeof(CallSendDtmf) ] = typeof( AtCallSendDtmf );
    }

} // namespace Gtm601

// vim:ts=4:sw=4:expandtab
