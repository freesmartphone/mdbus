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

namespace FsoAudio
{
    public interface IRouter : FsoFramework.AbstractObject
    {
        public abstract void set_mode( FreeSmartphone.Audio.Mode mode, bool force = false );
        public abstract void set_device( FreeSmartphone.Audio.Device device, bool expose = true );
        public abstract void set_volume( FreeSmartphone.Audio.Control control, uint volume );
        public abstract FreeSmartphone.Audio.Device[] get_available_devices( FreeSmartphone.Audio.Mode mode );
    }

    public abstract class AbstractRouter : IRouter, FsoFramework.AbstractObject
    {
        protected FreeSmartphone.Audio.Mode current_mode;
        protected FreeSmartphone.Audio.Device current_device;
        protected FreeSmartphone.Audio.Device[] call_supported_devices;
        protected FreeSmartphone.Audio.Device[] normal_supported_devices;

        public virtual void set_mode( FreeSmartphone.Audio.Mode mode, bool force = false )
        {
            current_mode = mode;
        }

        public virtual void set_device( FreeSmartphone.Audio.Device device, bool expose = true )
        {
            current_device = device;
        }

        public virtual void set_volume( FreeSmartphone.Audio.Control control, uint volume )
        {
        }

        public virtual FreeSmartphone.Audio.Device[] get_available_devices( FreeSmartphone.Audio.Mode mode )
        {
            FreeSmartphone.Audio.Device[] result = new FreeSmartphone.Audio.Device[] { };

            switch ( mode )
            {
                case FreeSmartphone.Audio.Mode.NORMAL:
                    result = normal_supported_devices;
                    break;
                case FreeSmartphone.Audio.Mode.CALL:
                    result = call_supported_devices;
                    break;
            }

            return result;
        }
    }

    public class NullRouter : AbstractRouter
    {
        public override FreeSmartphone.Audio.Device[] get_available_devices( FreeSmartphone.Audio.Mode mode )
        {
            return new FreeSmartphone.Audio.Device[] { };
        }

        public override string repr()
        {
            return "<>";
        }
    }
}

// vim:ts=4:sw=4:expandtab
