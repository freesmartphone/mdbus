/*
 * Copyright (C) 2011-2012 Simon Busch <morphis@gravedo.de>
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

/**
 * Handling the ALSA device on the Nexus S device is a little bit different then
 * everywhere else. Due to the kernel implementation of the wm8994 codec of the Android
 * Open Source Project the codec is only powered up when someone uses the ALSA PCM device.
 * If nobody is using it the codec will be reseted by the driver and all routing
 * information gets lost. On the android side there is a libaudio implementation for this
 * which is the primary target and source for sound on the android platform. It keeps the
 * ALSA PCM device open to deal with audio. We're doing here the following:
 *
 * We register a new private resource (it's not really a private one but one with a
 * not common name) which will then set a lock for the ALSA PCM device to keep it
 * available even when there is no component accessing the device. To safe some power
 * when the device is suspended we're unsetting the lock when the resource is suspend and
 * requiring it back when it gets resumed.
 * After the lock is set we need to reevaluate the current audio scenario.
 **/

namespace Herring
{
    internal class AlsaPcmDeviceAllocator : FsoFramework.AbstractObject
    {
        private Alsa.PcmDevice _device = null;
        private string _cardname = "default";

        public void take()
        {
            var rc = Alsa.PcmDevice.open( out _device, _cardname, Alsa.PcmStream.PLAYBACK );
            if ( rc < 0 || _device == null )
                logger.error( @"Failed to open PCM device" );
        }

        public void release()
        {
            if ( _device == null )
                return;

            _device.close();
            _device = null;
        }

        public override string repr()
        {
            return @"<>";
        }
    }

    public class AlsaPowerControl : FsoFramework.AbstractDBusResource
    {
        private AlsaPcmDeviceAllocator _pcm_allocator;
        private bool _powered;

        //
        // private
        //

        private async void set_power( bool on )
        {
            if ( ( on && _powered ) || ( !on && !_powered ) )
                return;

            _pcm_allocator.take();
            Posix.system( "/usr/bin/amixer set \"Codec Lock\" %s".printf( on ? "on" : "off" ) );
            _pcm_allocator.release();

            _powered = on;

            if ( _powered )
            {
                try
                {
                    logger.debug( @"Attempting to re-set current audio scenario" );

                    var proxy = yield Bus.get_proxy<FreeSmartphone.Device.Audio>( BusType.SYSTEM,
                        FsoFramework.Device.ServiceDBusName, FsoFramework.Device.AudioServicePath );

                    string current_scenario = yield proxy.get_scenario();
                    yield proxy.set_scenario( current_scenario );

                    logger.debug( @"Set current audio scenario \"$current_scenario\" again" );
                }
                catch ( GLib.Error error )
                {
                    logger.error( @"Failed to reset current audio scenario; audio support is limited now" );
                }
            }
        }

        //
        // public API
        //

        public AlsaPowerControl( FsoFramework.Subsystem subsystem )
        {
            base( "alsa-audio-private", subsystem );
            _powered = false;
            _pcm_allocator = new AlsaPcmDeviceAllocator();

            logger.info( "created." );
        }

        public override async void enableResource() throws FreeSmartphone.ResourceError
        {
            set_power( true );
        }

        public override async void disableResource()
        {
            set_power( false );
        }

        public override async void suspendResource()
        {
            yield disableResource();
        }

        public override async void resumeResource()
        {
            yield enableResource();
        }

        public override FreeSmartphone.UsageResourcePolicy default_policy()
        {
            return FreeSmartphone.UsageResourcePolicy.ENABLED;
        }
    }
}

// vim:ts=4:sw=4:expandtab
