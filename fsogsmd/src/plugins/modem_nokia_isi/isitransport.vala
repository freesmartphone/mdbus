/*
 * Copyright (C) 2011-2012 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
        // phase 1: modem & netlink
        if ( ! ( yield NokiaIsi.isimodem.connect() ) )
        {
            debug( "ISI PROBLEM in PHASE 1, FAIL" );
            return false;
        }

        // phase 2: launch subsystems
        if ( ! ( yield NokiaIsi.isimodem.launch() ) )
        {
            debug( "ISI PROBLEM in PHASE 2, FAIL" );
            return false;
        }

        // phase 2: launch subsystems
        if ( ! ( yield NokiaIsi.isimodem.startup() ) )
        {
            debug( "ISI PROBLEM in PHASE 3, FAIL" );
            return false;
        }

        debug( "ISI OPEN ASYNC OK" );

        return true;
    }
}

// vim:ts=4:sw=4:expandtab
