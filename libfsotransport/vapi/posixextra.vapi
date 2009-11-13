/* gplv2, (C) M.Lauer, scheduled for upstream inclusion */

[CCode (lower_case_cprefix = "")]
namespace PosixExtra {

    [CCode (cname = "struct sockaddr_in", cheader_filename = "netinet/in.h", destroy_function = "")]
    public struct SockAddrIn
    {
        public int sin_family;
        public uint16 sin_port;
        public Posix.InAddr sin_addr;
    }
}

