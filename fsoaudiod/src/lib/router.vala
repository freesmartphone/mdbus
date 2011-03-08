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

namespace FsoAudio
{
    public interface IRouter : FsoFramework.AbstractObject
    {
        public abstract void set_mode( FreeSmartphone.Audio.Mode mode );
        public abstract void set_output_device( FreeSmartphone.Audio.Device device );
        public abstract void set_volume( uint volume );
        public abstract FreeSmartphone.Audio.Device[] get_available_output_devices( FreeSmartphone.Audio.Mode mode );
    }

    public abstract class AbstractRouter : IRouter, FsoFramework.AbstractObject
    {
        protected FreeSmartphone.Audio.Mode current_mode;
        protected FreeSmartphone.Audio.Device current_output_device;
        protected FreeSmartphone.Audio.Device[] call_supported_outputs;
        protected FreeSmartphone.Audio.Device[] normal_supported_outputs;

        public virtual void set_mode( FreeSmartphone.Audio.Mode mode )
        {
            current_mode = mode;
        }

        public virtual void set_output_device( FreeSmartphone.Audio.Device device )
        {
            current_output_device = device;
        }

        public virtual void set_volume( uint volume )
        {
        }

        public virtual FreeSmartphone.Audio.Device[] get_available_output_devices( FreeSmartphone.Audio.Mode mode )
        {
            FreeSmartphone.Audio.Device[] result = new FreeSmartphone.Audio.Device[] { };

            switch ( mode )
            {
                case FreeSmartphone.Audio.Mode.NORMAL:
                    result = normal_supported_outputs;
                    break;
                case FreeSmartphone.Audio.Mode.CALL:
                    result = call_supported_outputs;
                    break;
            }

            return result;
        }
    }

    public class NullRouter : AbstractRouter
    {
        public override FreeSmartphone.Audio.Device[] get_available_output_devices( FreeSmartphone.Audio.Mode mode )
        {
            return new FreeSmartphone.Audio.Device[] { };
        }

        public override string repr()
        {
            return "<>";
        }
    }
}
