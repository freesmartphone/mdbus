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

    public string callStatusToString( int code )
    {
        switch ( code )
        {
            case 0:
                return "active";
            case 1:
                return "held";
            case 2:
                return "outgoing"; // we don't distinguish between alerting and outgoing
            case 3:
                return "outgoing";
            case 4:
                return "incoming";
            case 5:
                return "incoming";
            default:
                return "unknown";
        }
    }

    public FreeSmartphone.GSM.CallStatus callStatusToEnum( int code )
    {
        switch ( code )
        {
            case 0:
                return FreeSmartphone.GSM.CallStatus.ACTIVE;
            case 1:
                return FreeSmartphone.GSM.CallStatus.HELD;
            case 2:
            case 3:
                return FreeSmartphone.GSM.CallStatus.OUTGOING;
            case 4:
            case 5:
                return FreeSmartphone.GSM.CallStatus.INCOMING;
            default:
                warning( "invalid call status!!! setting to RELEASE" );
                return FreeSmartphone.GSM.CallStatus.RELEASE;
        }
    }

    public string callDirectionToString( int code )
    {
        switch ( code )
        {
            case 0:
                return "outgoing";
            case 1:
                return "incoming";
            default:
                error( "invalid call status: %d", code );
                return "unknown";
        }
    }
    public int callStringToType( string ctype )
    {
        switch ( ctype )
        {
            case "voice":
                return 0;
            case "data":
                return 1;
            case "fax":
                return 2;
            case "voice;data:voice":
                return 3;
            case "voice/data:voice":
                return 4;
            case "voice/fax:voice":
                return 5;
            case "voice;data:data":
                return 6;
            case "voice/data:data":
                return 7;
            case "voice/fax:fax":
                return 8;
            case "unknown":
                return 9;
            default:
                error( "invalid call type: %s", ctype );
                return 9;
        }
    }

    public string callTypeToString( int code )
    {
        switch ( code )
        {
            case 0:
                return "voice";
            case 1:
                return "data";
            case 2:
                return "fax";
            case 3:
                return "voice;data:voice";
            case 4:
                return "voice/dat:voice";
            case 5:
                return "voice/fax:voice";
            case 6:
                return "voice;data:data";
            case 7:
                return "voice/data:data";
            case 8:
                return "voice/fax:fax";
            default:
                return "unknown";
        }
    }
}


