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
        public abstract void set_output( string name );
        public abstract void set_input( string name );
        public abstract void set_volume( uint volume );
        public abstract string[] get_available_input_devices();
        public abstract string[] get_available_output_devices();
    }

    public abstract class AbstractRouter : IRouter, FsoFramework.AbstractObject
    {
        public abstract void set_mode( FreeSmartphone.Audio.Mode mode );
        public abstract void set_output( string name );
        public abstract void set_input( string name );
        public abstract void set_volume( uint volume );
        public abstract string[] get_available_input_devices();
        public abstract string[] get_available_output_devices();

    }

    public class NullRouter : AbstractRouter
    {
        public override void set_mode( FreeSmartphone.Audio.Mode mode )
        {
        }

        public override void set_output( string name )
        {
        }

        public override void set_input( string name )
        {
        }

        public override void set_volume( uint volume )
        {
        }

        public override string[] get_available_input_devices()
        {
            return new string[] { };
        }

        public override string[] get_available_output_devices()
        {
            return new string[] { };
        }

        public override string repr()
        {
            return "<>";
        }
    }
}
