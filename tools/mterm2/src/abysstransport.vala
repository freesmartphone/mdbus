/**
 * This file is part of fso-term.
 *
 * (C) 2009 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
 **/

//===========================================================================
public class AbyssTransport : FsoFramework.SerialTransport
//===========================================================================
{
    public AbyssTransport( int channelspec )
    {
        // gather a channel via DBus

        DBus.Connection conn = DBus.Bus.get( DBus.BusType.SYSTEM );
        dynamic DBus.Object muxer = conn.get_object( "org.freesmartphone.omuxerd",
                                                     "/org/freesmartphone/GSM/Muxer",
                                                     "org.freesmartphone.GSM.MUX" );

        string portname;
        int channel;

        try
        {
            muxer.AllocChannel( "fso-term", channelspec, out portname, out channel );
            base( portname, 115200 );
        }
        catch ( DBus.Error e )
        {
            stderr.printf( "FATAL: Error from fso-abyss: %s\n", e.message );
        }
    }
}
