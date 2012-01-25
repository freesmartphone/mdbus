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
using Gee;
using FsoFramework;

namespace FsoAudio
{
    public abstract class AbstractSessionPolicy : AbstractObject
    {
        protected AbstractStreamControl stream_control;

        public abstract void handleConnectingStream( FreeSmartphone.Audio.Stream stream );
        public abstract void handleDisconnectingStream( FreeSmartphone.Audio.Stream stream );

        public void provideStreamControl( AbstractStreamControl stream_control )
        {
            this.stream_control = stream_control;
        }

        public override string repr()
        {
            return "<>";
        }
    }

    public class NullSessionPolicy : AbstractSessionPolicy
    {
        public override void handleConnectingStream( FreeSmartphone.Audio.Stream stream )
        {
            logger.warning( "NullSessionPolicy::handleConnectingStream(): This is maybe not what you want!" );
        }

        public override void handleDisconnectingStream( FreeSmartphone.Audio.Stream stream )
        {
            logger.warning( "NullSessionPolicy::handleDisconnectingStream(): This is maybe not what you want!" );
        }
    }
}

// vim:ts=4:sw=4:expandtab
