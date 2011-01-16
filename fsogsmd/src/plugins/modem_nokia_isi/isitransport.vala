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

using GLib;
using FsoGsm;

//===========================================================================
public class IsiTransport : FsoFramework.NullTransport
//===========================================================================
{
    private bool reachable = false;
    private string iface;

    public IsiTransport( string iface )
    {
        base( "IsiTransport" );
        this.iface = iface;
    }

    public override string repr()
    {
        return iface != null ? @"<$iface>" : "<unknown>";
    }

    public override bool open()
    {
        assert_not_reached(); // this transport can only be opened async
    }

    public override bool isOpen()
    {
        return reachable;
    }

    public override async bool openAsync()
    {
        reachable = true;

        NokiaIsi.modem.isimodem = new ISI.Modem( iface, (err) => {
            if ( err )
            {
                logger.error( "Modem not reachable" );
                reachable = false;
            }
            else
            {
                logger.info( "Modem is reachable" );
                NokiaIsi.modem.isidevice = new ISI.DeviceInfo( NokiaIsi.modem.isimodem, (err) => {
                    logger.warning( "Device subsystem not reachable" );
                } );
                NokiaIsi.modem.isisimauth = new ISI.SIMAuth( NokiaIsi.modem.isimodem );
                NokiaIsi.modem.isinetwork = new ISI.Network( NokiaIsi.modem.isimodem, (err) => {
                    logger.warning( "Network subsystem not reachable" );
                } );
            }
        } );

        // wait 3 seconds for modem to come up
        Timeout.add_seconds( 3, () => { openAsync.callback(); return false; } );

        yield;

        return reachable;
    }
}
