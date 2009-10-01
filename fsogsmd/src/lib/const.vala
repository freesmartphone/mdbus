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

/**
 * Constant functions etc.
 **/

public class FsoGsm.Constants
{
    internal static FsoGsm.Constants _instance;

    public static FsoGsm.Constants instance()
    {
        if ( _instance == null )
        {
            _instance = new FsoGsm.Constants();
        }
        return _instance;
    }

    private Constants()
    {
        // init...
    }

    // public API
    public string networkProviderStatusToString( int code )
    {
        switch ( code )
        {
            case 1:
                return "available";
            case 2:
                return "current";
            case 3:
                return "forbidden";
            default:
                return "unknown";
        }
    }

    public string networkProviderActToString( int code )
    {
        switch ( code )
        {
            case 1:
                return "Compact GSM";
            case 2:
                return "UMTS";
            case 3:
                return "EDGE";
            case 4:
                return "HSDPA";
            case 5:
                return "HSUPA";
            case 6:
                return "HSDPA/HSUPA";
            default:
                return "GSM";
        }
    }

    public string deviceBatteryStatusToString( int code )
    {
        switch ( code )
        {
            case 0:
                return "battery";
            case 1:
                return "ac";
            case 2:
                return "usb";
            case 3:
                return "failure";
            default:
                return "unknown";
        }
    }
}

