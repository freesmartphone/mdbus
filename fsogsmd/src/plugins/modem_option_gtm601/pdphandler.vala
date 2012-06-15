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

    private FsoGsm.Modem modem;

    public void assign_modem( FsoGsm.Modem modem )
    {
        this.modem = modem;
    }

    public override string repr()
    {
        return "<>";
    }

    public async override void sc_activate() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var data = modem.data();
        var activated = false;

        if ( data.contextParams == null )
        {
            throw new FreeSmartphone.Error.INTERNAL_ERROR( "Context parameters not set" );
        }

        if ( data.contextParams.apn == null )
        {
            throw new FreeSmartphone.Error.INTERNAL_ERROR( "APN not set" );
        }

        var cmd_owancall = modem.createAtCommand<Gtm601.UnderscoreOWANCALL>( "_OWANCALL" );
        var cmd_owandata = modem.createAtCommand<Gtm601.UnderscoreOWANDATA>( "_OWANDATA" );
        string[] response = { };

        try
        {
            response = yield modem.processAtCommandAsync( cmd_owancall, cmd_owancall.issue( true ) );
            checkResponseOk( cmd_owancall, response );
            activated = true;

            Timeout.add_seconds( 5, () => { sc_activate.callback(); return false; } );
            yield;

            response = yield modem.processAtCommandAsync( cmd_owandata, cmd_owandata.issue() );
            checkResponseValid( cmd_owandata, response );

            if ( !cmd_owandata.connected )
                throw new FreeSmartphone.Error.INTERNAL_ERROR( @"Modem reports that PDP session is not yet established!" );

            var route = new FsoGsm.RouteInfo() {
                iface = HSO_IFACE,
                ipv4addr = cmd_owandata.ip,
                ipv4mask = "255.255.255.0",
                ipv4gateway = cmd_owandata.gateway,
                dns1 = cmd_owandata.dns1,
                dns2 = cmd_owandata.dns2
            };

            connectedWithNewDefaultRoute( route );
        }
        catch ( GLib.Error e )
        {
            if ( activated )
            {
                response = yield modem.processAtCommandAsync( cmd_owancall, cmd_owancall.issue( false ) );
                checkResponseOk( cmd_owancall, response );
            }

            throw new FreeSmartphone.Error.INTERNAL_ERROR( @"Failed to active PDP context: $(e.message)" );
        }
    }

    public async override void sc_deactivate()
    {
        try
        {
            var cmd = modem.createAtCommand<Gtm601.UnderscoreOWANCALL>( "_OWANCALL" );
            var response = yield modem.processAtCommandAsync( cmd, cmd.issue( false ) );
            checkResponseOk( cmd, response );
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
