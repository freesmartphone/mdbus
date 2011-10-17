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

public class Samsung.UnsolicitedResponseHandler : FsoFramework.AbstractObject
{
    /**
     * Handling the various possible unsolicited responses we get from the modem
     **/
    public void process( SamsungIpc.Response response )
    {
        switch ( response.command )
        {
            case SamsungIpc.MessageType.PWR_PHONE_PWR_UP:
                break;
            case SamsungIpc.MessageType.NET_REGIST:
                handle_network_registration( response );
                break;
        }
    }

    public override string repr()
    {
        return @"<>";
    }

    //
    // private
    //

    private void handle_network_registration( SamsungIpc.Response response )
    {
        SamsungIpc.Network.RegistrationMessage* reginfo = (SamsungIpc.Network.RegistrationMessage*) response.data;

        assert( logger.debug( @"Got network registration information from modem:" ) );
        assert( logger.debug( @" act = $(reginfo.act), domain = $(reginfo.domain)" ) );
        assert( logger.debug( @" status = $(reginfo.status), edge = $(reginfo.edge)" ) );
        assert( logger.debug( @" lac = $(reginfo.lac), cid = $(reginfo.lac), rej_cause = $(reginfo.rej_cause)" ) );
    }
}

