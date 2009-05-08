/**
 * Copyright (C) 2009 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 */

using GLib;

/**
 * @class FsoFramework.BaseKObjectNotifier
 **/
public class FsoFramework.BaseKObjectNotifier : Object
{
    private int fd = -1;
    private uint watch;
    private IOChannel channel;

    private char[] buffer;

    private const ssize_t BUFFER_LENGTH = 4096;

    public BaseKObjectNotifier()
    {
        buffer = new char[BUFFER_LENGTH];

        fd = Posix.socket( Linux26.Netlink.AF_NETLINK, Posix.SOCK_DGRAM, Linux26.Netlink.NETLINK_KOBJECT_UEVENT );
        assert( fd != -1 );

        Linux26.Netlink.SockAddrNl addr = { Linux26.Netlink.AF_NETLINK,
                                            0,
                                            PosixExtra.getpid(),
                                            1 };

        var res = PosixExtra.bind( fd, &addr, sizeof( Linux26.Netlink.SockAddrNl ) );
        assert( res != -1 );

        channel = new IOChannel.unix_new( fd );
        watch = channel.add_watch( IOCondition.IN | IOCondition.HUP, onActionFromSocket );

    }

    public void addMatch()
    {
        message( "yo" );
    }

    public bool onActionFromSocket( IOChannel source, IOCondition condition )
    {
        if ( ( condition & IOCondition.HUP ) == IOCondition.HUP )
        {
            warning( "HUP on kobject uevent socket. will no longer get any notifications" );
            return false;
        }

        if ( ( condition & IOCondition.IN ) == IOCondition.IN )
        {
            assert( fd != -1 );
            assert( buffer != null );
            ssize_t bytesread = Posix.read( fd, buffer, BUFFER_LENGTH );

            message( "got message from socket: %s", (string)buffer );

            return true;
        }

        assert_not_reached();
    }

}

