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
using Gee;
using FsoFramework;

namespace FsoAudio
{
    public abstract class AbstractAudioSessionPolicy : AbstractObject
    {
        public abstract void handleConnectingStream( FreeSmartphone.Audio.Stream stream );
        public abstract void handleDisconnectingStream( FreeSmartphone.Audio.Stream stream );

        public override string repr()
        {
            return "<>";
        }
    }

    public class NullAudioSessionPolicy : AbstractAudioSessionPolicy
    {
        public override void handleConnectingStream( FreeSmartphone.Audio.Stream stream )
        {
            logger.warning( "NullAudioSessionPolicy::handleConnectingStream(): This is maybe not what you want!" );
        }

        public override void handleDisconnectingStream( FreeSmartphone.Audio.Stream stream )
        {
            logger.warning( "NullAudioSessionPolicy::handleDisconnectingStream(): This is maybe not what you want!" );
        }
    }
}
