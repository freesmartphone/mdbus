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
    public const string PHONE_DIGITS = """0123456789ABCD*#+pw""";
    public const string PHONE_DIGITS_RE = """[0-9A-D\*#\+pw]""";

    public enum SimCommand
    {
        READ_BINARY         = 176,
        READ_RECORD         = 192,
        UPDATE_BINARY       = 214,
        UPDATE_RECORD       = 220,
        STATUS              = 242,
    }

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
    public string devicePowerStatusToString( int code )
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

    public string deviceFunctionalityStatusToString( int code )
    {
        switch ( code )
        {
            case 0:
                return "minimal";
            case 1:
                return "full";
            case 4:
                return "airplane";
            default:
                return "unknown";
        }
    }

    public int deviceFunctionalityStringToStatus( string level )
    {
        switch ( level )
        {
            case "minimal":
                return 0;
            case "full":
                return 1;
            case "airplane":
                return 4;
            default:
                return -1;
        }
    }

    public string simPhonebookNameToString( string name )
    {
        switch ( name )
        {
            case "DC":
                return "dialed";
            case "EN":
                return "emergency";
            case "FD":
                return "fixed";
            case "MC":
                return "missed";
            case "ON":
                return "own";
            case "RC":
                return "received";
            case "SM":
                return "contacts";
            case "VM":
                return "voicebox";
            default:
                return "unknown:%s".printf( name );
        }
    }

    public string simPhonebookStringToName( string category )
    {
        switch ( category )
        {
            case "dialed":
                return "DC";
            case "emergency":
                return "EN";
            case "fixed":
                return "FD";
            case "missed":
                return "MC";
            case "own":
                return "ON";
            case "received":
                return "RC";
            case "contacts":
                return "SM";
            case "voicebox":
                return "VM";
            default:
                return "";
        }
    }

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

    public string phonenumberTupleToString( string number, int ntype )
    {
        if ( ntype == 145 ) // must not include '+' then, but some modems violate the spec
        {
            if ( number[0] == '+' )
            {
                return number;
            }
            else
            {
                return "+%s".printf( number );
            }
        }
        else
        {
            return number;
        }
    }

    public string phonenumberStringToTuple( string number )
    {
        if ( number[0] == '+' )
        {
            return """"%s",145""".printf( number.offset( 1 ) );
        }
        else
        {
            return """"%s",129""".printf( number );
        }
    }
}

