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

using GLib;

namespace FsoDevice {

public abstract class BaseAccelerometer : FsoFramework.AbstractObject
{
    public BaseAccelerometer()
    {
    }

    public void setThreshold( int mg )
    {
    }

    public void setRate( uint ms )
    {
    }

    public abstract void start();

    public abstract void stop();

    public abstract signal void acceleration( int x, int y, int z );

    public override string repr()
    {
        return "<>";
    }
}
private static Gee.HashMap<string,BaseAccelerometer> _accels;
public BaseAccelerometer getAccelerometer( string type )
{
    if( _accels == null )
         _accels = new Gee.HashMap<string,BaseAccelerometer>();

    var accel = _accels.get( type );
    if( _accels == null )
    {
        switch( type )
        {
            case "lis302":
                var t = Type.from_name( "HardwareAccelerometerLis302" );
                accel = Object.new( t ) as BaseAccelerometer;
                _accels.set( "lis302", accel );
                break;
            default:
                debug( @"Can not lookup accelerometer for $type" );
                break;
        }
    }
    return accel;

}

}
