/**
 * Copyright (C) 2009-2012 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

public interface AudioRouter : GLib.Object
{
    public abstract bool isScenarioAvailable( string scenario );
    public abstract string[] availableScenarios();
    public abstract string currentScenario();
    public abstract string pullScenario() throws FreeSmartphone.Device.AudioError;
    public abstract void pushScenario( string scenario );
    public abstract void setScenario( string scenario );
    public abstract void saveScenario( string scenario ) throws FreeSmartphone.Error;
    public abstract uint8 currentVolume() throws FreeSmartphone.Error;
    public abstract void setVolume( uint8 volume ) throws FreeSmartphone.Error;
}

public class NullRouter : AudioRouter, GLib.Object
{
    public bool isScenarioAvailable( string scenario )
    {
        return false;
    }

    public string[] availableScenarios()
    {
        return {};
    }

    public string currentScenario()
    {
        return "";
    }

    public string pullScenario() throws FreeSmartphone.Device.AudioError
    {
        return "";
    }

    public void pushScenario( string scenario )
    {
    }

    public void setScenario( string scenario )
    {
    }

    public void saveScenario( string scenario ) throws FreeSmartphone.Error
    {
    }

    public uint8 currentVolume() throws FreeSmartphone.Error
    {
        return 0;
    }

    public void setVolume( uint8 volume ) throws FreeSmartphone.Error
    {
    }
}

public abstract class BaseAudioRouter : AudioRouter, GLib.Object
{
    public abstract bool isScenarioAvailable( string scenario );
    public abstract string[] availableScenarios();
    public abstract string currentScenario();
    public abstract string pullScenario() throws FreeSmartphone.Device.AudioError;
    public abstract void pushScenario( string scenario );
    public abstract void setScenario( string scenario );
    public abstract void saveScenario( string scenario ) throws FreeSmartphone.Error;

    public virtual uint8 currentVolume() throws FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.UNSUPPORTED( "Not Implemented" );
    }

    public virtual void setVolume( uint8 volume ) throws FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.UNSUPPORTED( "Not Implemented" );
    }
}

} /* namespace FsoDevice */

// vim:ts=4:sw=4:expandtab
