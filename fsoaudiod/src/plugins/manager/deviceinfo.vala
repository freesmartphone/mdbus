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
     * Saves controls for both modes normal and call and their states and offers a simple
     * API to manage them.
     **/
    public class DeviceInfo
    {
        public FreeSmartphone.Audio.Device type;
        public ControlInfo[] call_controls;
        public ControlInfo[] normal_controls;

        public DeviceInfo( FreeSmartphone.Audio.Device type )
        {
            this.type = type;
            normal_controls = new ControlInfo[] {
                new ControlInfo( FreeSmartphone.Audio.Control.SPEAKER, 80 ),
                new ControlInfo( FreeSmartphone.Audio.Control.MICROPHONE, 80 )
            };
            call_controls = new ControlInfo[] {
                new ControlInfo( FreeSmartphone.Audio.Control.SPEAKER, 80 ),
                new ControlInfo( FreeSmartphone.Audio.Control.MICROPHONE, 80 )
            };
        }

        private ControlInfo[] get_controls( FreeSmartphone.Audio.Mode mode )
        {
            return mode == FreeSmartphone.Audio.Mode.NORMAL ? normal_controls : call_controls;
        }

        public void set_volume( FreeSmartphone.Audio.Mode mode, FreeSmartphone.Audio.Control ctrl, int volume )
        {
            var controls = get_controls( mode );
            controls[ ctrl ].volume = volume;
        }

        public int get_volume( FreeSmartphone.Audio.Mode mode, FreeSmartphone.Audio.Control ctrl )
        {
            var controls = get_controls( mode );
            return controls[ ctrl ].volume;
        }

        public void set_mute( FreeSmartphone.Audio.Mode mode, FreeSmartphone.Audio.Control ctrl, bool mute )
        {
            var controls = get_controls( mode );
            controls[ ctrl].muted = mute;
        }

        public bool get_mute( FreeSmartphone.Audio.Mode mode, FreeSmartphone.Audio.Control ctrl )
        {
            var controls = get_controls( mode );
            return controls[ ctrl ].muted;
        }
    }
}

// vim:ts=4:sw=4:expandtab
