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

    /**
     * SIM Filesystem
     **/
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

    public enum SimFilesystemCommand
    {
        READ_BINARY         = 176,
        READ_RECORD         = 192,
        UPDATE_BINARY       = 214,
        UPDATE_RECORD       = 220,
        STATUS              = 242,
    }

    /**
     * At response codes
     **/
    public enum AtResponse
    {
        VALID = 0,
        OK = 1,
        UNEXPECTED_LENGTH = 501,
        UNABLE_TO_PARSE = 502,
        ERROR = 503,

        CME_ERROR_START = 1000,
        CME_ERROR_000_PHONE_FAILURE = 1000,
        CME_ERROR_001_NO_CONNECTION_TO_PHONE = 1001,
        CME_ERROR_002_PHONE_ADAPTER_LINK_RESERVED = 1002,
        CME_ERROR_003_OPERATION_NOT_ALLOWED = 1003,
        CME_ERROR_004_OPERATION_NOT_SUPPORTED = 1004,
        CME_ERROR_005_PH_SIM_PIN_REQUIRED = 1005,
        CME_ERROR_006_PH_FSIM_PIN_REQUIRED = 1006,
        CME_ERROR_007_PH_FSIM_PUK_REQUIRED = 1007,
        CME_ERROR_010_SIM_NOT_INSERTED = 1010,
        CME_ERROR_011_SIM_PIN_REQUIRED = 1011,
        CME_ERROR_012_SIM_PUK_REQUIRED = 1012,
        CME_ERROR_013_SIM_FAILURE = 1013,
        CME_ERROR_014_SIM_BUSY = 1014,
        CME_ERROR_015_SIM_WRONG = 1015,
        CME_ERROR_016_INCORRECT_PASSWORD = 1016,
        CME_ERROR_017_SIM_PIN2_REQUIRED = 1017,
        CME_ERROR_018_SIM_PUK2_REQUIRED = 1018,
        CME_ERROR_020_MEMORY_FULL = 1020,
        CME_ERROR_021_INVALID_INDEX = 1021,
        CME_ERROR_022_NOT_FOUND = 1022,
        CME_ERROR_023_MEMORY_FAILURE = 1023,
        CME_ERROR_024_TEXT_STRING_TOO_LONG = 1024,
        CME_ERROR_025_INVALID_CHARACTERS_IN_TEXT_STRING = 1025,
        CME_ERROR_026_DIAL_STRING_TOO_LONG = 1026,
        CME_ERROR_027_INVALID_CHARACTERS_IN_DIAL_STRING = 1027,
        CME_ERROR_030_NO_NETWORK_SERVICE = 1030,
        CME_ERROR_031_NETWORK_TIMEOUT = 1031,
        CME_ERROR_032_NETWORK_NOT_ALLOWED_EMERGENCY_CALLS_ONLY = 1032,
        CME_ERROR_040_NETWORK_PERSONALIZATION_PIN_REQUIRED = 1040,
        CME_ERROR_041_NETWORK_PERSONALIZATION_PUK_REQUIRED = 1041,
        CME_ERROR_042_NETWORK_SUBSET_PERSONALIZATION_PIN_REQUIRED = 1042,
        CME_ERROR_043_NETWORK_SUBSET_PERSONALIZATION_PUK_REQUIRED = 1043,
        CME_ERROR_044_SERVICE_PROVIDER_PERSONALIZATION_PIN_REQUIRED = 1044,
        CME_ERROR_045_SERVICE_PROVIDER_PERSONALIZATION_PUK_REQUIRED = 1045,
        CME_ERROR_046_CORPORATE_PERSONALIZATION_PIN_REQUIRED = 1046,
        CME_ERROR_047_CORPORATE_PERSONALIZATION_PUK_REQUIRED = 1047,
        CME_ERROR_048_PH_SIM_PUK_REQUIRED = 1048,
        CME_ERROR_100_UNKNOWN_ERROR = 1100,
        CME_ERROR_103_GPRS_ILLEGAL_MS = 1103,
        CME_ERROR_106_GPRS_ILLEGAL_ME = 1106,
        CME_ERROR_107_GPRS_SERVICES_NOT_ALLOWED = 1107,
        CME_ERROR_111_GPRS_PLMN_NOT_ALLOWED = 1111,
        CME_ERROR_112_GPRS_LOCATION_AREA_NOT_ALLOWED = 1112,
        CME_ERROR_113_GPRS_ROAMING_NOT_ALLOWED_IN_THIS_LOCATION_AREA = 1113,
        CME_ERROR_126_GPRS_OPERATION_TEMPORARY_NOT_ALLOWED = 1126,
        CME_ERROR_132_GPRS_SERVICE_OPERATION_NOT_SUPPORTED = 1132,
        CME_ERROR_133_GPRS_REQUESTED_SERVICE_OPTION_NOT_SUBSCRIBED = 1133,
        CME_ERROR_134_GPRS_SERVICE_OPTION_TEMPORARY_OUT_OF_ORDER = 1134,
        CME_ERROR_148_GPRS_UNSPECIFIED_ERROR = 1148,
        CME_ERROR_149_GPRS_PDP_AUTHENTICATION_FAILURE = 1149,
        CME_ERROR_150_GPRS_INVALID_MOBILE_CLASS = 1150,
        CME_ERROR_256_OPERATION_TEMPORARILY_NOT_ALLOWED = 1256,
        CME_ERROR_257_CALL_BARRED = 1257,
        CME_ERROR_258_PHONE_IS_BUSY = 1258,
        CME_ERROR_259_USER_ABORT = 1259,
        CME_ERROR_260_INVALID_DIAL_STRING = 1260,
        CME_ERROR_261_SS_NOT_EXECUTED = 1261,
        CME_ERROR_262_SIM_BLOCKED = 1262,
        CME_ERROR_263_INVALID_BLOCK = 1263,
        CME_ERROR_265_BUSY_TRY_AGAIN = 1265,
        CME_ERROR_512_FAILED_TO_ABORT_COMMAND = 1512,
        CME_ERROR_513_ACM_RESET_NEEDED = 1513,
        CME_ERROR_514_SIM_APPLICATION_TOOLKIT_BUSY = 1514,
        CME_ERROR_772_SIM_POWERED_DOWN = 1772,

        CMS_ERROR_START = 2000,
        CMS_ERROR_001_UNASSIGNED_NUMBER = 2001,
        CMS_ERROR_008_OPERATOR_DETERMINED_BARRING = 2008,
        CMS_ERROR_010_CALL_BARED = 2010,
        CMS_ERROR_021_SHORT_MESSAGE_TRANSFER_REJECTED = 2021,
        CMS_ERROR_027_DESTINATION_OUT_OF_SERVICE = 2027,
        CMS_ERROR_028_UNIDENTIFIED_SUBSCRIBER = 2028,
        CMS_ERROR_029_FACILITY_REJECTED = 2029,
        CMS_ERROR_030_UNKNOWN_SUBSCRIBER = 2030,
        CMS_ERROR_038_NETWORK_OUT_OF_ORDER = 2038,
        CMS_ERROR_041_TEMPORARY_FAILURE = 2041,
        CMS_ERROR_042_CONGESTION = 2042,
        CMS_ERROR_047_RECOURCES_UNAVAILABLE = 2047,
        CMS_ERROR_050_REQUESTED_FACILITY_NOT_SUBSCRIBED = 2050,
        CMS_ERROR_069_REQUESTED_FACILITY_NOT_IMPLEMENTED = 2069,
        CMS_ERROR_081_INVALID_SHORT_MESSAGE_TRANSFER_REFERENCE_VALUE = 2081,
        CMS_ERROR_095_INVALID_MESSAGE_UNSPECIFIED = 2095,
        CMS_ERROR_096_INVALID_MANDATORY_INFORMATION = 2096,
        CMS_ERROR_097_MESSAGE_TYPE_NON_EXISTENT_OR_NOT_IMPLEMENTED = 2097,
        CMS_ERROR_098_MESSAGE_NOT_COMPATIBLE_WITH_SHORT_MESSAGE_PROTOCOL = 2098,
        CMS_ERROR_099_INFORMATION_ELEMENT_NON_EXISTENT_OR_NOT_IMPLEMENTED = 2099,
        CMS_ERROR_111_PROTOCOL_ERROR_UNSPECIFIED = 2111,
        CMS_ERROR_127_INTERNETWORKING_UNSPECIFIED = 2127,
        CMS_ERROR_128_TELEMATIC_INTERNETWORKING_NOT_SUPPORTED = 2128,
        CMS_ERROR_129_SHORT_MESSAGE_TYPE_0_NOT_SUPPORTED = 2129,
        CMS_ERROR_130_CANNOT_REPLACE_SHORT_MESSAGE = 2130,
        CMS_ERROR_143_UNSPECIFIED_TP_PID_ERROR = 2143,
        CMS_ERROR_144_DATA_CODE_SCHEME_NOT_SUPPORTED = 2144,
        CMS_ERROR_145_MESSAGE_CLASS_NOT_SUPPORTED = 2145,
        CMS_ERROR_159_UNSPECIFIED_TP_DCS_ERROR = 2159,
        CMS_ERROR_160_COMMAND_CANNOT_BE_ACTIONED = 2160,
        CMS_ERROR_161_COMMAND_UNSUPPORTED = 2161,
        CMS_ERROR_175_UNSPECIFIED_TP_COMMAND_ERROR = 2175,
        CMS_ERROR_176_TPDU_NOT_SUPPORTED = 2176,
        CMS_ERROR_192_SC_BUSY = 2192,
        CMS_ERROR_193_NO_SC_SUBSCRIPTION = 2193,
        CMS_ERROR_194_SC_SYSTEM_FAILURE = 2194,
        CMS_ERROR_195_INVALID_SME_ADDRESS = 2195,
        CMS_ERROR_196_DESTINATION_SME_BARRED = 2196,
        CMS_ERROR_197_SM_REJECTED_DUPLICATE_SM = 2197,
        CMS_ERROR_198_TP_VPF_NOT_SUPPORTED = 2198,
        CMS_ERROR_199_TP_VP_NOT_SUPPORTED = 2199,
        CMS_ERROR_208_D0_SIM_SMS_STORAGE_FULL = 2208,
        CMS_ERROR_209_NO_SMS_STORAGE_CAPABILITY_IN_SIM = 2209,
        CMS_ERROR_210_ERROR_IN_MS = 2210,
        CMS_ERROR_211_MEMORY_CAPACITY_EXCEEDED = 2211,
        CMS_ERROR_212_SIM_APPLICATION_TOOLKIT_BUSY = 2212,
        CMS_ERROR_213_SIM_DATA_DOWNLOAD_ERROR = 2213,
        CMS_ERROR_255_UNSPECIFIED_ERROR_CAUSE = 2255,
        CMS_ERROR_300_ME_FAILURE = 2300,
        CMS_ERROR_301_SMS_SERVICE_OF_ME_RESERVED = 2301,
        CMS_ERROR_302_OPERATION_NOT_ALLOWED = 2302,
        CMS_ERROR_303_OPERATION_NOT_SUPPORTED = 2303,
        CMS_ERROR_304_INVALID_PDU_MODE_PARAMETER = 2304,
        CMS_ERROR_305_INVALID_TEXT_MODE_PARAMETER = 2305,
        CMS_ERROR_310_SIM_NOT_INSERTED = 2310,
        CMS_ERROR_311_SIM_PIN_REQUIRED = 2311,
        CMS_ERROR_312_PH_SIM_PIN_REQUIRED = 2312,
        CMS_ERROR_313_SIM_FAILURE = 2313,
        CMS_ERROR_314_SIM_BUSY = 2314,
        CMS_ERROR_315_SIM_WRONG = 2315,
        CMS_ERROR_316_SIM_PUK_REQUIRED = 2316,
        CMS_ERROR_317_SIM_PIN2_REQUIRED = 2317,
        CMS_ERROR_318_SIM_PUK2_REQUIRED = 2318,
        CMS_ERROR_320_MEMORY_FAILURE = 2320,
        CMS_ERROR_321_INVALID_MEMORY_INDEX = 2321,
        CMS_ERROR_322_MEMORY_FULL = 2322,
        CMS_ERROR_330_SMSC_ADDRESS_UNKNOWN = 2330,
        CMS_ERROR_331_NO_NETWORK_SERVICE = 2331,
        CMS_ERROR_332_NETWORK_TIMEOUT = 2332,
        CMS_ERROR_340_NO_CNMA_EXPECTED = 2340,
        CMS_ERROR_500_UNKNOWN_ERROR = 2500,
        CMS_ERROR_512_FAILED_TO_ABORT_COMMAND = 2512,
        CMS_ERROR_513_ACM_RESET_NEEDED = 2513,
        CMS_ERROR_514_INVALID_STATUS = 2514,
        CMS_ERROR_515_DEVICE_BUSY_OR_INVALID_CHARACTER_IN_STRING = 2515,
        CMS_ERROR_516_INVALID_LENGTH = 2516,
        CMS_ERROR_517_INVALID_CHARACTER_IN_PDU = 2517,
        CMS_ERROR_518_INVALID_PARAMETER = 2518,
        CMS_ERROR_519_INVALID_LENGTH_OR_CHARACTER = 2519,
        CMS_ERROR_520_INVALID_CHARACTER_IN_TEXT = 2520,
        CMS_ERROR_521_TIMER_EXPIRED = 2521,
        CMS_ERROR_522_OPERATION_TEMPORARY_NOT_ALLOWED = 2522,
        CMS_ERROR_532_SIM_NOT_READY = 2532,
        CMS_ERROR_534_CELL_BROADCAST_ERROR_UNKNOWN = 2534,
        CMS_ERROR_535_PROTOCOL_STACK_BUSY = 2535,
        CMS_ERROR_538_INVALID_PARAMETER = 2538,

        EXT_ERROR_START = 3000,
        EXT_ERROR_0_INVALID_PARAMETERR = 3000,
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

    //
    // public API
    //
    public FreeSmartphone.GSM.Error atResponseCodeToError( AtResponse code, string detail )
    {
        switch ( code )
        {
            case AtResponse.CME_ERROR_010_SIM_NOT_INSERTED:
                return new FreeSmartphone.GSM.Error.SIM_NOT_PRESENT( detail );

            case AtResponse.CME_ERROR_005_PH_SIM_PIN_REQUIRED:
            case AtResponse.CME_ERROR_006_PH_FSIM_PIN_REQUIRED:
            case AtResponse.CME_ERROR_007_PH_FSIM_PUK_REQUIRED:
            case AtResponse.CME_ERROR_011_SIM_PIN_REQUIRED:
            case AtResponse.CME_ERROR_012_SIM_PUK_REQUIRED:
            case AtResponse.CME_ERROR_017_SIM_PIN2_REQUIRED:
            case AtResponse.CME_ERROR_018_SIM_PUK2_REQUIRED:
            case AtResponse.CME_ERROR_040_NETWORK_PERSONALIZATION_PIN_REQUIRED:
            case AtResponse.CME_ERROR_041_NETWORK_PERSONALIZATION_PUK_REQUIRED:
            case AtResponse.CME_ERROR_042_NETWORK_SUBSET_PERSONALIZATION_PIN_REQUIRED:
            case AtResponse.CME_ERROR_043_NETWORK_SUBSET_PERSONALIZATION_PUK_REQUIRED:
            case AtResponse.CME_ERROR_044_SERVICE_PROVIDER_PERSONALIZATION_PIN_REQUIRED:
            case AtResponse.CME_ERROR_045_SERVICE_PROVIDER_PERSONALIZATION_PUK_REQUIRED:
            case AtResponse.CME_ERROR_046_CORPORATE_PERSONALIZATION_PIN_REQUIRED:
            case AtResponse.CME_ERROR_047_CORPORATE_PERSONALIZATION_PUK_REQUIRED:
            case AtResponse.CME_ERROR_048_PH_SIM_PUK_REQUIRED:
                return new FreeSmartphone.GSM.Error.AUTHORIZATION_REQUIRED( detail );

            default:
                return new FreeSmartphone.GSM.Error.DEVICE_FAILED( detail );
        }
    }

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
            case "LD":
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
                return "unsupported:%s".printf( name );
        }
    }

    public string simPhonebookStringToName( string category )
    {
        switch ( category )
        {
            case "dialed":
                return "LD";
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
                if ( category.has_prefix( "unknown:" ) )
                {
                    return ( category.replace( "unknown:", "" ) );
                }
                else
                {
                    return "";
                }
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
            case 3:
                return "outgoing";
            case 4:
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


