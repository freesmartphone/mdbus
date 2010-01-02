/**
 * Copyright (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
 **/

static void fsogsmd_ppp_on_exit( int arg )
{
    debug( "fsogsmd plugin on_exit" );
}

static void fsogsmd_snoop_send_packet( char[] packet )
{
    debug( "sending packet with length %d", packet.length );
}

static void plugin_init()
{
    debug( "fsogsmd plugin init" );
    PPPD.add_notifier( PPPD.exitnotify, fsogsmd_ppp_on_exit );
}
