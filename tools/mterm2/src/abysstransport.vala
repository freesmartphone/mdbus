/*
 * (C) 2009-2012 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 */

//===========================================================================
public class AbyssTransport : FsoFramework.SerialTransport
//===========================================================================
{
    public AbyssTransport( int channelspec )
    {
        // gather a channel via DBus
        try
        {

            var muxer = Bus.get_proxy_sync<FreeSmartphone.GSM.MUXSync>( BusType.SYSTEM, "org.freesmartphone.omuxerd", "/org/freesmartphone/GSM/Muxer" );
            string portname;
            int channel;
            muxer.alloc_channel( "mterm2", channelspec, out portname, out channel );
            base( portname, 115200 );
        }
        catch ( Error e )
        {
            stderr.printf( @"FATAL: $(e.message)" );
        }
    }
}

// vim:ts=4:sw=4:expandtab
