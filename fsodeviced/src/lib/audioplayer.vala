/**
 * Copyright (C) 2009 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
namespace FsoDevice
{

public interface AudioPlayer : GLib.Object
{   
    public abstract async void play_sound( string name, int loop, int length ) throws FreeSmartphone.Device.AudioError, FreeSmartphone.Error;
    public abstract async void stop_sound( string name ) throws FreeSmartphone.Error;
    public abstract async void stop_all_sounds();
}

public class NullPlayer : AudioPlayer, GLib.Object
{
    public async void play_sound( string name, int loop, int length ) throws FreeSmartphone.Device.AudioError, FreeSmartphone.Error
    {
    }

    public async void stop_sound( string name ) throws FreeSmartphone.Error
    {
    }
    
    public async void stop_all_sounds()
    {
    }
}

} /* namespace FsoDevice */
