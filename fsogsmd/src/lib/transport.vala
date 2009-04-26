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

//===========================================================================
public class LibGsm0710muxTransport : FsoFramework.BaseTransport
//===========================================================================
{
    Gsm0710mux.Manager manager;
    Gsm0710mux.ChannelInfo channelinfo;

    public LibGsm0710muxTransport( int channel = 0 )
    {
        manager = new Gsm0710mux.Manager();
        var version = manager.getVersion();
        var hasAutoSession = manager.hasAutoSession();
        assert( hasAutoSession ); // we do not support non-autosession yet

        channelinfo.number = channel;

        debug( "TransportLibGsm0710mux created, using libgsm0710mux version %s; autosession is %s".printf( version, hasAutoSession.to_string() ) );
    }

    public override bool open()
    {
        assert( readfunc != null );
        assert( hupfunc != null );

        channelinfo.type = Gsm0710mux.ChannelType.DELEGATE;
        channelinfo.readfunc = readfunc;
        channelinfo.hupfunc = hupfunc;

        try
        {
            manager.allocChannel( ref channelinfo );
        }
        catch ( FsoFramework.TransportError e )
        {
            debug( "error: %s", e.message );
            return false;
        }

        return true;
    }

    public override string repr()
    {
        return "<LibGsm0710muxTransport>";
    }

}
