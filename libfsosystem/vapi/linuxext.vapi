[CCode (cprefix = "", lower_case_cprefix = "")]
namespace LinuxExt
{
    /*
     * Wireless Extensions (WEXT) Infrastructure
     */
    [CCode (cprefix = "", lower_case_cprefix = "")]
    namespace WirelessExtensions
    {
        [CCode (cname = "struct iw_point", has_type_id = false, cheader_filename = "linux/wireless.h", destroy_function = "")]
        public struct IwPoint
        {
            public void *pointer;
            public uint16 length;
            public uint16 flags;
        }

        [CCode (cname = "struct iw_param", has_type_id = false, cheader_filename = "linux/wireless.h", destroy_function = "")]
        public struct IwParam
        {
            public int32 value;
            public uint8 fixed;
            public uint8 disabled;
            public uint16 flags;
        }

        [CCode (cname = "struct iw_freq", has_type_id = false, cheader_filename = "linux/wireless.h", destroy_function = "")]
        public struct IwFreq
        {
            public int32 m;
            public int16 e;
            public uint8 i;
            public uint8 flags;
        }

        [CCode (cname = "struct iw_quality", has_type_id = false, cheader_filename = "linux/wireless.h", destroy_function = "")]
        public struct IwQuality
        {
            public uint8 qual;
            public uint8 level;
            public uint8 noise;
            public uint8 updated;
        }

        [CCode (cname = "struct iwreq_data", has_type_id = false, cheader_filename = "linux/wireless.h", destroy_function = "")]
        public struct IwReqData
        {
            [CCode (array_length = false)]
            public string name;
            public IwPoint essid;
            public IwParam nwid;
            public IwFreq freq;
            public IwParam sens;
            public IwParam bitrate;
            public IwParam txpower;
            public IwParam rts;
            public IwParam frag;
            public uint32 mode;
            public IwParam retry;
            public IwPoint encoding;
            public IwParam power;
            public IwQuality qual;
            public Posix.SockAddr ap_addr;
            public Posix.SockAddr addr;
            public IwParam param;
            public IwPoint data;
        }

        [CCode (cname = "struct iwreq", has_type_id = false, cheader_filename = "linux/wireless.h", destroy_function = "")]
        public struct IwReq
        {
            [CCode (array_length = false)]
            public char[] ifr_name;
            public IwReqData u;
        }
    }
}
