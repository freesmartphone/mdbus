/*
 * Copyright (C) 2011 Simon Busch <morphis@gravedo.de>
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

DBusConnection conn = null;
string active_token;
bool registered;

static const string FSOAUDIO_BUSNAME = "org.freesmartphone.oaudiod";
static const string FSOAUDIO_PATH = "/org/freesmartphone/Audio";
static const string FSOAUDIO_MANAGER_IFNAME = "org.freesmartphone.Audio.Manager";

static const int timeout = 10;

public int fsoaudio_request_session()
{
    registered = false;
    active_token = "";

    try
    {
        conn = Bus.get_sync( BusType.SYSTEM );

        // FIXME currently we default to media stream type. We should choose the right
        // stream according to the device the user wants to open
        var params = new Variant[] {
            new Variant.string( "media" )
        };

        Variant result = conn.call_sync( FSOAUDIO_BUSNAME, FSOAUDIO_PATH, FSOAUDIO_MANAGER_IFNAME,
                                     "RegisterSession", params, VariantType.STRING,
                                     DBusCallFlags.NO_AUTO_START, timeout );

        if ( result.is_of_type( VariantType.STRING ) )
        {
            active_token = result.get_string();
            registered = true;
        }
    }
    catch ( Error err )
    {
    }

    return registered ? 0 : -1;
}

public int fsoaudio_release_session()
{
    if ( registered && conn != null && active_token.length > 0 )
    {
        try
        {
            var params = new Variant[] {
                new Variant.string( active_token )
            };

            Variant result = conn.call_sync( FSOAUDIO_BUSNAME, FSOAUDIO_PATH, FSOAUDIO_MANAGER_IFNAME,
                                             "ReleaseSession", params, VariantType.ANY,
                                             DBusCallFlags.NO_AUTO_START, timeout );

            registered = false;
        }
        catch ( Error err )
        {
        }
    }

    return 0;
}

// vim:ts=4:sw=4:expandtab
