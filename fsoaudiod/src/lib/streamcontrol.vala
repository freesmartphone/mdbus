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
    public abstract class AbstractStreamControl : AbstractObject
    {
        /**
         * Setup up various apsects of the the stream control
         **/
        public abstract void setup();

        public abstract void set_mute( FreeSmartphone.Audio.Stream stream, bool mute );
        public abstract void set_volume( FreeSmartphone.Audio.Stream stream, uint level );
        public abstract bool get_mute( FreeSmartphone.Audio.Stream stream );
        public abstract uint get_volume( FreeSmartphone.Audio.Stream stream );

        public signal void volume_changed( FreeSmartphone.Audio.Stream stream, uint level );
        public signal void mute_changed( FreeSmartphone.Audio.Stream stream, bool mute );

        public override string repr()
        {
            return "<>";
        }
    }

    public class NullStreamControl : AbstractStreamControl
    {
        public override void setup()
        {
            logger.warning( @"NullStreamControl::setup(): This is probably not what you want!" );
        }

        public override void set_mute( FreeSmartphone.Audio.Stream stream, bool mute )
        {
            logger.warning( @"NullStreamControl::set_mute(): This is probably not what you want!" );
        }

        public override void set_volume( FreeSmartphone.Audio.Stream stream, uint level )
        {
            logger.warning( @"NullStreamControl::set_volume(): This is probably not what you want!" );
        }

        public override bool get_mute( FreeSmartphone.Audio.Stream stream )
        {
            logger.warning( @"NullStreamControl::get_mute(): This is probably not what you want!" );
            return false;
        }

        public override uint get_volume( FreeSmartphone.Audio.Stream stream )
        {
            logger.warning( @"NullStreamControl::get_volume(): This is probably not what you want!" );
            return 100;
        }
    }
}

// vim:ts=4:sw=4:expandtab
