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

public class BasePowerControl : FreeSmartphone.Device.PowerControl, FsoFramework.AbstractObject
{
    private string powernode;
    private string onvalue;
    private string offvalue;
    private uint switchtimeout;

    protected static uint counter;

    public BasePowerControl( string? powernode = null, string onvalue = "1", string offvalue = "0", uint switchtimeout = 3 )
    {
        this.powernode = powernode;
        this.onvalue = onvalue;
        this.offvalue = offvalue;
        this.switchtimeout = switchtimeout;
    }

    public override string repr()
    {
        return "<@ powernode %s>".printf( powernode );
    }

    public virtual bool getPower()
    {
        assert( powernode != null );
        var value = FsoFramework.FileHandling.read( powernode );
        return value == onvalue;
    }

    public virtual void setPower( bool on )
    {
        assert( powernode != null );
        if ( on == getPower() )
            return;

        FsoFramework.FileHandling.write( on ? onvalue : offvalue, powernode );
    }

    // DBUS API
    public bool get_power() throws DBus.Error
    {
        return getPower();
    }

    public void set_power( bool on ) throws DBus.Error
    {
        setPower( on );
    }

}

}
