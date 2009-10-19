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

    public const uint CALL_INDEX_MAX = 7;

    public struct SimFilesystemEntry
    {
        public int id;
        public int parent;
        public string name;
    }

    public const SimFilesystemEntry[] SimFilesystem =
    {
        { 0x3F00,        0x0000,      "MF" },           // root

        { 0x2FE2,        0x3F00,      "EFiccid" },
        { 0x2F05,        0x3F00,      "EFelp" },

        { 0x7F10,        0x3F00,      "DFtelecom" },
        { 0x6F3A,        0x7F10,      "EFadn" },
        { 0x6F3B,        0x7F10,      "EFfdn" },
        { 0x6F3C,        0x7F10,      "EFsms" },
        { 0x6F3D,        0x7F10,      "EFccp" },
        { 0x6F40,        0x7F10,      "EFmsisdn" },
        { 0x6F42,        0x7F10,      "EFsmsp" },
        { 0x6F43,        0x7F10,      "EFsmss" },
        { 0x6F44,        0x7F10,      "EFlnd" },
        { 0x6F47,        0x7F10,      "EFsmsr" },
        { 0x6F49,        0x7F10,      "EFsdn" },
        { 0x6F4A,        0x7F10,      "EFext1" },
        { 0x6F4B,        0x7F10,      "EFext2" },
        { 0x6F4C,        0x7F10,      "EFext3" },
        { 0x6F4D,        0x7F10,      "EFbdn" },
        { 0x6F4E,        0x7F10,      "EFext4" },
        { 0x6F4F,        0x7F10,      "EFeccp" },          // 51.011
        { 0x6F58,        0x7F10,      "EFcmi" },           // 51.011

        { 0x5F50,        0x7F10,      "DFgraphics" },
        { 0x4F20,        0x5F50,      "EFimg" },
        { 0x4F01,        0x5F50,      "EFimg1" },          // Usual names of
        { 0x4F02,        0x5F50,      "EFimg2" },          // Image data files.
        { 0x4F03,        0x5F50,      "EFimg3" },
        { 0x4F04,        0x5F50,      "EFimg4" },
        { 0x4F05,        0x5F50,      "EFimg5" },

        { 0x7F20,        0x3F00,      "DFgsm" },
        { 0x6F05,        0x7F20,      "EFlp" },
        { 0x6F07,        0x7F20,      "EFimsi" },
        { 0x6F20,        0x7F20,      "EFkc" },
        { 0x6F2C,        0x7F20,      "EFdck" },           // 51.011
        { 0x6F30,        0x7F20,      "EFplmnsel" },
        { 0x6F31,        0x7F20,      "EFhpplmn" },
        { 0x6F32,        0x7F20,      "EFcnl" },           // 51.011
        { 0x6F37,        0x7F20,      "EFacmmax" },
        { 0x6F38,        0x7F20,      "EFsst" },
        { 0x6F39,        0x7F20,      "EFacm" },
        { 0x6F3E,        0x7F20,      "EFgid1" },
        { 0x6F3F,        0x7F20,      "EFgid2" },
        { 0x6F41,        0x7F20,      "EFpuct" },
        { 0x6F45,        0x7F20,      "EFcbmi" },
        { 0x6F46,        0x7F20,      "EFspn" },           // SIM Provider Name
        { 0x6F48,        0x7F20,      "EFcbmid" },
        { 0x6F50,        0x7F20,      "EFcbmir" },
        { 0x6F51,        0x7F20,      "EFnia" },
        { 0x6F52,        0x7F20,      "EFkcgprs" },
        { 0x6F53,        0x7F20,      "EFlocigprs" },
        { 0x6F54,        0x7F20,      "EFsume" },
        { 0x6F60,        0x7F20,      "EFplmnwact" },
        { 0x6F61,        0x7F20,      "EFoplmnwact" },
        { 0x6F62,        0x7F20,      "EFhplmnwact" },
        { 0x6F63,        0x7F20,      "EFcpbcch" },
        { 0x6F64,        0x7F20,      "EFinvscan" },
        { 0x6F74,        0x7F20,      "EFbcch" },
        { 0x6F78,        0x7F20,      "EFacc" },
        { 0x6F7B,        0x7F20,      "EFfplmn" },
        { 0x6F7E,        0x7F20,      "EFloci" },
        { 0x6FAD,        0x7F20,      "EFad" },
        { 0x6FAE,        0x7F20,      "EFphase" },
        { 0x6FB1,        0x7F20,      "EFvgcs" },
        { 0x6FB2,        0x7F20,      "EFvgcss" },
        { 0x6FB3,        0x7F20,      "EFvbs" },
        { 0x6FB4,        0x7F20,      "EFvbss" },
        { 0x6FB5,        0x7F20,      "EFemlpp" },
        { 0x6FB6,        0x7F20,      "EFaaem" },
        { 0x6FB7,        0x7F20,      "EFecc" },
        { 0x6FC5,        0x7F20,      "EFpnn" },           // 51.011
        { 0x6FC6,        0x7F20,      "EFopl" },           // 51.011
        { 0x6FC7,        0x7F20,      "EFmbdn" },          // 51.011
        { 0x6FC8,        0x7F20,      "EFext6" },          // 51.011
        { 0x6FC9,        0x7F20,      "EFmbi" },           // 51.011
        { 0x6FCA,        0x7F20,      "EFmwis" },          // 51.011
        { 0x6FCB,        0x7F20,      "EFcfis" },          // 51.011
        { 0x6FCC,        0x7F20,      "EFext7" },          // 51.011
        { 0x6FCD,        0x7F20,      "EFspdi" },          // 51.011
        { 0x6FCE,        0x7F20,      "EFmmsn" },          // 51.011
        { 0x6FCF,        0x7F20,      "EFext8" },          // 51.011
        { 0x6FD0,        0x7F20,      "EFmmsicp" },        // 51.011
        { 0x6FD1,        0x7F20,      "EFmmsup" },         // 51.011
        { 0x6FD2,        0x7F20,      "EFmmsucp" },        // 51.011

        { 0x5F30,        0x7F20,      "DFiridium" },
        { 0x5F31,        0x7F20,      "DFglobst" },
        { 0x5F32,        0x7F20,      "DFico" },
        { 0x5F33,        0x7F20,      "DFaces" },

        { 0x5F40,        0x7F20,      "DFeia/tia-553" },
        { 0x4F80,        0x5F40,      "EFsid" },           // 51.011
        { 0x4F81,        0x5F40,      "EFgpi" },           // 51.011
        { 0x4F82,        0x5F40,      "EFipc" },           // 51.011
        { 0x4F83,        0x5F40,      "EFcount" },         // 51.011
        { 0x4F84,        0x5F40,      "EFnsid" },          // 51.011
        { 0x4F85,        0x5F40,      "EFpsid" },          // 51.011
        { 0x4F86,        0x5F40,      "EFnetsel" },        // 51.011
        { 0x4F87,        0x5F40,      "EFspl" },           // 51.011
        { 0x4F88,        0x5F40,      "EFmin" },           // 51.011
        { 0x4F89,        0x5F40,      "EFaccolc" },        // 51.011
        { 0x4F8A,        0x5F40,      "EFfc1" },           // 51.011
        { 0x4F8B,        0x5F40,      "EFs-esn" },         // 51.011
        { 0x4F8C,        0x5F40,      "EFcsid" },          // 51.011
        { 0x4F8D,        0x5F40,      "EFreg-thresh" },    // 51.011
        { 0x4F8E,        0x5F40,      "EFccch" },          // 51.011
        { 0x4F8F,        0x5F40,      "EFldcc" },          // 51.011
        { 0x4F90,        0x5F40,      "EFgsm-recon" },     // 51.011
        { 0x4F91,        0x5F40,      "EFamps-2-gsm" },    // 51.011
        { 0x4F93,        0x5F40,      "EFamps-ui" },       // 51.011

        { 0x5F60,        0x7F20,      "DFcts" },

        { 0x5F70,        0x7F20,      "DFsolsa" },
        { 0x4F30,        0x5F70,      "EFsai" },
        { 0x4F31,        0x5F70,      "EFsll" },

        { 0x5F3C,        0x7F20,      "DFmexe" },
        { 0x4F40,        0x5F3C,      "EFmexe-st" },
        { 0x4F41,        0x5F3C,      "EForpk" },
        { 0x4F42,        0x5F3C,      "EFarpk" },
        { 0x4F43,        0x5F3C,      "EFtprpk" },

        { 0x7F22,        0x3F00,      "DFis41" },

        { 0x7F23,        0x3F00,      "DFfp-cts" }
    };

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

    public int simFilesystemEntryNameToCode( string name )
    {
        foreach ( var entry in SimFilesystem )
        {
            if ( entry.name == name )
            {
                return entry.id;
            }
        }
        warning( "simFilesystemEntryNameToCode: '%s' not found", name );
        return -1; // not found
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

    public string networkRegistrationModeToString( int code )
    {
        switch ( code )
        {
            case 0:
                return "automatic";
            case 1:
                return "manual";
            case 2:
                return "unregister";
            case 4:
                return "manual;automatic";
            default:
                return "unknown";
        }
    }

    public string networkRegistrationStatusToString( int code )
    {
        switch ( code )
        {
            case 0:
                return "unregistered";
            case 1:
                return "home";
            case 2:
                return "searching";
            case 3:
                return "denied";
            case 5:
                return "roaming";
            default:
                return "unknown";
        }
    }

    public int networkSignalToPercentage( int signal )
    {
        if ( signal <= 0 || signal > 31 )
        {
            return 0;
        }
        double dsig = signal;
        var dpercentage = Math.round( Math.log10( dsig ) / Math.log10( 31.0 ) * 100 );

        return (int)dpercentage;
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

    public FreeSmartphone.GSM.SIMAuthStatus simAuthStatusToEnum( string status )
    {
        switch ( status )
        {
            case "READY":
                return FreeSmartphone.GSM.SIMAuthStatus.READY;
            case "SIM PIN":
                return FreeSmartphone.GSM.SIMAuthStatus.PIN_REQUIRED;
            case "SIM PUK":
                return FreeSmartphone.GSM.SIMAuthStatus.PUK_REQUIRED;
            case "SIM PIN2":
                return FreeSmartphone.GSM.SIMAuthStatus.PIN2_REQUIRED;
            case "SIM PUK2":
                return FreeSmartphone.GSM.SIMAuthStatus.PUK2_REQUIRED;
            default:
                warning( "unknown SIM PIN status %s!!!", status );
                return FreeSmartphone.GSM.SIMAuthStatus.UNKNOWN;
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


