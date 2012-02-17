/*
 * Copyright (C) 2011-2012 Simon Busch <morphis@gravedo.de>
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

public class Samsung.CommandHandler : FsoFramework.AbstractCommandHandler
{
    public unowned SamsungIpc.Client client;
    public uint8 id;
    public SamsungIpc.RequestType request_type;
    public SamsungIpc.MessageType message_type;
    public uint8[] data;
    public unowned SamsungIpc.Response response;
    public bool timed_out = false;

    public override void writeToTransport( FsoFramework.Transport t )
    {
        assert( theLogger.debug( @"Sending request with id = $(id), request_type = $(request_type), " +
                                 @"message_type = $(message_type) " ) );

        assert( theLogger.debug( @"request data (length = $(data.length)):" ) );
        assert( theLogger.debug( "\n" + FsoFramework.StringHandling.hexdump( data ) ) );

        client.send( message_type, request_type, data, id );
    }

    public override string to_string()
    {
        return @"<>";
    }
}

// vim:ts=4:sw=4:expandtab
