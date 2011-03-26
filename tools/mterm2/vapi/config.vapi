[CCode (cprefix = "", lower_case_cprefix = "", cheader_filename = "config.h")]
namespace Config
{
    public const string PACKAGE_VERSION;
    public const string PACKAGE_DATADIR;
}

namespace Linux
{
    [CCode (cname = "makedev", cheader_filename = "sys/types.h")]
    public Posix.dev_t makedev( int maj, int min );
    [CCode (cname = "major", cheader_filename = "sys/types.h")]
    public int major( Posix.dev_t dev );
    [CCode (cname = "minor", cheader_filename = "sys/types.h")]
    public int minor( Posix.dev_t dev );

    namespace Gsm
    {
        [CCode (cname = "GSMIOC_GETCONF", cheader_filename = "linux/gsmmux.h")]
        public const int GSMIOC_GETCONF;
        [CCode (cname = "GSMIOC_SETCONF", cheader_filename = "linux/gsmmux.h")]
        public const int GSMIOC_SETCONF;

        [CCode (cname = "struct gsm_config", cheader_filename = "linux/gsmmux.h")]
        public struct Config
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
