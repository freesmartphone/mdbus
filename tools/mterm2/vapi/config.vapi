[CCode (cprefix = "", lower_case_cprefix = "", cheader_filename = "config.h")]
namespace Config
{
    public const string PACKAGE_VERSION;
    public const string PACKAGE_DATADIR;
}

namespace LinuxExt
{
    namespace Tty
    {
        [CCode (cname = "GSMIOC_GETCONF", cheader_filename = "linux/gsmmux.h")]
        public const int GSMIOC_GETCONF;
        [CCode (cname = "GSMIOC_SETCONF", cheader_filename = "linux/gsmmux.h")]
        public const int GSMIOC_SETCONF;

        [CCode (cname = "struct gsm_config", cheader_filename = "linux/gsmmux.h")]
        public struct GsmMuxConfig
        {
            public uint adaption;
            public uint encapsulation;
            public uint initiator;
            public uint t1;
            public uint t2;
            public uint t3;
            public uint n2;
            public uint mru;
            public uint mtu;
            public uint k;
            public uint i;
        }
    } /* namespace Tty */
}
