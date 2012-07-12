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
using Alsa;

internal class Herring.AlsaStreamKeeper : FsoFramework.AbstractObject
{
    private PcmDevice pcm;
    private string cardname = "default";

    //
    // public API
    //

    public AlsaStreamKeeper()
    {
        var rc = PcmDevice.open( out pcm, cardname, PcmStream.PLAYBACK );
        if ( rc < 0 || pcm == null )
            logger.error( @"Failed to open PCM device" );
    }

    ~AlsaStreamKeeper()
    {
        if ( pcm != null )
        {
            pcm.close();
        }
    }

    public override string repr()
    {
        return @"<>";
    }
}

// vim:ts=4:sw=4:expandtab
