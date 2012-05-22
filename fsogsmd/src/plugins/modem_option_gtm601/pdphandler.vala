/*
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *                         Klaus 'mrmoku' Kurzmann <mok@fluxnetz.de>
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

/**
 * @class Pdp.OptionGtm601
 *
 * Pdp Handler implemented with the proprietary Qualcomm Management Interface protocol
 **/
class Pdp.OptionGtm601 : FsoGsm.PdpHandler
{
    public const string MODULE_NAME = "fsogsm.pdp_option_gtm601";
    public const string HSO_IFACE = "hso0";

    public override string repr()
    {
        return "<>";
    }

    public async override void sc_activate() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var data = theModem.data();

        if ( data.contextParams == null )
        {
            throw new FreeSmartphone.Error.INTERNAL_ERROR( "Context parameters not set" );
        }

        if ( data.contextParams.apn == null )
        {
            throw new FreeSmartphone.Error.INTERNAL_ERROR( "APN not set" );
        }

        try
        {
            var cmd = theModem.createAtCommand<Gtm601.UnderscoreOWANCALL>( "_OWANCALL" );
            var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( true ) );
            checkResponseConnect( cmd, response );
        }
        catch ( GLib.Error e )
        {
            throw new FreeSmartphone.Error.INTERNAL_ERROR( @"Failed to execute _OWANCALL command to activate PDP context: $(e.message)" );
        }

        try
        {
            var cmd2 = theModem.createAtCommand<Gtm601.UnderscoreOWANDATA>( "_OWANDATA" );
            var response2 = yield theModem.processAtCommandAsync( cmd2, cmd2.issue() );
            checkResponseOk( cmd2, response2 );

            if ( !cmd2.connected )
                throw new FreeSmartphone.Error.INTERNAL_ERROR( @"Modem reports that PDP session is not yet established!" );

            assert( logger.debug( @"Got IP configuration from modem:" ) );
            assert( logger.debug( @"local = $(cmd2.ip)" ) );
            assert( logger.debug( @"gateway = $(cmd2.gateway), dns1 = $(cmd2.dns1), dns2 = $(cmd2.dns2)" ) );

            var route = new FsoGsm.RouteInfo() {
                iface = HSO_IFACE,
                ipv4addr = cmd2.ip,
                ipv4mask = "255.255.255.0",
                ipv4gateway = cmd2.gateway,
                dns1 = cmd2.dns1,
                dns2 = cmd2.dns2
            };

            connectedWithNewDefaultRoute( route );
        }
        catch ( GLib.Error e2 )
        {
            throw new FreeSmartphone.Error.INTERNAL_ERROR( @"Failed to execute _OWANDATA to retrieve PDP context configuration from modem: $(e2.message)" );
        }
    }

    public async override void sc_deactivate()
    {
        try
        {
            var cmd = theModem.createAtCommand<Gtm601.UnderscoreOWANCALL>( "_OWANCALL" );
            var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( false ) );
            checkResponseConnect( cmd, response );
        }
        catch ( GLib.Error e )
        {
            logger.error( @"Failed to execute _OWANDATA command to deactivate PDP context: $(e.message)" );
        }
    }

    public async override void statusUpdate( string status, GLib.HashTable<string,Variant> properties )
    {
        assert_not_reached();
    }
}

// vim:ts=4:sw=4:expandtab
