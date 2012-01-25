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
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

using GLib;
using FsoFramework;

namespace FsoAudio
{
    /**
     * Information about a simple control like volume, mute status.
     **/
    public class ControlInfo
    {
        public FreeSmartphone.Audio.Control type;
        public int volume;
        public bool muted;

        public ControlInfo( FreeSmartphone.Audio.Control type, int volume )
        {
            this.type = type;
            this.volume = volume;
            this.muted = ( this.volume == 0 );
        }
    }
}

// vim:ts=4:sw=4:expandtab
