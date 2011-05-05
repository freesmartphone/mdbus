/*
 * const.vala: constants and helper functions
 *
 * (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

public errordomain Gsm0710mux.MuxerError
{
    CHANNEL_TAKEN,
    INVALID_CHANNEL,
    INVALID_TRANSPORT,
    NO_SESSION,
    NO_CHANNEL,
    SESSION_ALREADY_OPEN,
    SESSION_OPEN_ERROR,
}

namespace CONST
{
    //===========================================================================
    internal const string LIBGSM0710MUX_CONFIG_SECTION = "libgsm0710mux";
    internal const string LIBGSM0710MUX_LOGGING_DOMAIN = "libgsm0710mux";

    internal const uint GSM_PING_SEND_TIMEOUT = 5;
    internal const uint GSM_PING_RESPONSE_TIMEOUT = 3;

    internal const int TRANSPORT_READ_PRIORITY = -20;
    internal const int TRANSPORT_WRITE_PRIORITY = 0;

    //===========================================================================
    internal void hexdump( bool write, void* data, int len, FsoFramework.Logger logger )
    {
        if ( len < 1 )
            return;

        int BYTES_PER_LINE = 16;

        uchar* pointer = (uchar*) data;
        var hexline = new StringBuilder( write? ">>> " : "<<< " );
        var ascline = new StringBuilder();
        uchar b;
        int i;

        for ( i = 0; i < len; ++i )
        {
            b = pointer[i];
            hexline.append_printf( "%02X ", b );
            if ( 31 < b && b < 128 )
                ascline.append_printf( "%c", b );
            else
                ascline.append_printf( "." );

            if ( i % BYTES_PER_LINE+1 == BYTES_PER_LINE )
            {
                hexline.append( ascline.str );
                logger.debug( hexline.str );
                hexline = new StringBuilder( write? ">>> " : "<<< " );
                ascline = new StringBuilder();
            }
        }
        if ( i % BYTES_PER_LINE+1 != BYTES_PER_LINE )
        {
            while ( hexline.len < 52 )
                hexline.append_c( ' ' );

            hexline.append( ascline.str );
            logger.debug( hexline.str );
        }
    }
}

// vim:ts=4:sw=4:expandtab
