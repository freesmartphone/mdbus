/*
 * Copyright (C) 2011 Simon Busch <morphis@gravedo.de>
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
using FsoFramework;

public class Samsung.NetworkStatus : FsoFramework.AbstractObject
{
    private uint id = 0;
    private bool inTriggerUpdateNetworkStatus = false;

    public bool active { get; private set; default = false; }
    public int interval { get; set; default = 5; }

    //
    // public API
    //

    public void start()
    {
        if ( active )
            return;

        assert( logger.debug( @"Start to poll network status ..." ) );
        id = Timeout.add_seconds( interval, () => {
            triggerUpdateNetworkStatus();
            return true;
        } );

        active = true;
    }

    public void stop()
    {
        if ( !active )
            return;

        assert( logger.debug( @"Stop polling network status ..." ) );
        Source.remove( id );
        active = false;
    }

    public override string repr()
    {
        return @"<>";
    }
}

// vim:ts=4:sw=4:expandtab
