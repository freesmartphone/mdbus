/*
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
using GIsiComm;

/**
 * @class Pdp.Isi
 *
 * Pdp Handler implemented with the proprietary Qualcomm Management Interface protocol
 **/
class Pdp.NokiaIsi : FsoGsm.PdpHandler
{
    public const string MODULE_NAME = "fsogsm.pdp_nokia_isi";

    public override string repr()
    {
        return "<>";
    }

    construct
    {
    }

    public async override void sc_activate() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var data = theModem.data();
        GIsiComm.ModemAccess isimodem = FsoFramework.DataSharing.valueForKey( "NokiaIsi.isimodem") as GIsiComm.ModemAccess;

        isimodem.gpds.contextActivated.connect( onContextActivated );
        isimodem.gpds.contextDeactivated.connect( onContextDeactivated );

        if ( data.contextParams == null )
        {
            throw new FreeSmartphone.Error.INTERNAL_ERROR( "Context parameters not set" );
        }

        if ( data.contextParams.apn == null )
        {
            throw new FreeSmartphone.Error.INTERNAL_ERROR( "APN not set" );
        }

        isimodem.gpds.activate( data.contextParams.apn, data.contextParams.username, data.contextParams.password, ( err ) => {
            if ( err != ErrorCode.OK )
                throw new FreeSmartphone.Error.INTERNAL_ERROR( "Failed to activate the GPRS context" );
        } );
    }

    public async override void sc_deactivate()
    {
        GIsiComm.ModemAccess isimodem = FsoFramework.DataSharing.valueForKey( "NokiaIsi.isimodem") as GIsiComm.ModemAccess;
        isimodem.gpds.deactivate();
    }

    public async override void statusUpdate( string status, GLib.HashTable<string,Variant> properties )
    {
        assert_not_reached();
    }

    private void onContextActivated( string iface, string ip, string dns1, string dns2 )
    {
        this.connectedWithNewDefaultRoute( iface, ip, "255.255.255.255", "0.0.0.0", dns1, dns2 );
    }

    private void onContextDeactivated()
    {
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
    FsoFramework.theLogger.debug( "pdp_nokia_isi fso_factory_function" );
    //var config = FsoFramework.theConfig;

    return Pdp.NokiaIsi.MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    // do not remove this function
}

// vim:ts=4:sw=4:expandtab
