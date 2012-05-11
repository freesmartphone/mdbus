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
            var cmd = FsoFramework.DataSharing.valueForKey( "Gtm601.OWANCALL") as FsoGsm.SimpleAtCommand<bool>;
            var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( true ) );
            checkResponseConnect( cmd, response );
        }
        catch ( GLib.Error e )
        {
            logger.error( @"Failed to execute _OWANCALL command to activate PDP context: $(e.message)" );
        }
    }

    public async override void sc_deactivate()
    {
        try
        {
            var cmd = FsoFramework.DataSharing.valueForKey( "Gtm601.OWANDATA") as FsoGsm.SimpleAtCommand<bool>;
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


/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    FsoFramework.theLogger.debug( "pdp_option_gtm601 fso_factory_function" );

    return Pdp.OptionGtm601.MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    // do not remove this function
}

// vim:ts=4:sw=4:expandtab
