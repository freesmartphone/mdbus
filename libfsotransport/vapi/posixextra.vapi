/* gplv2, (C) M.Lauer, scheduled for upstream inclusion */

[CCode (lower_case_cprefix = "")]
namespace PosixExtra {

    [CCode (cheader_filename = "arpa/inet.h")]
    public weak string inet_ntoa (PosixExtra.InAddr addr);

    [CCode (cheader_filename = "arpa/inet.h")]
    public int inet_aton(string cp, out PosixExtra.InAddr addr);

    [SimpleType]
    [CCode (cname = "struct in_addr", cheader_filename = "sys/socket.h", destroy_function = "")]
    public struct InAddr {
        public uint32 s_addr;
    }

    [CCode (cname = "struct sockaddr_in", cheader_filename = "netinet/in.h", destroy_function = "")]
    public struct SockAddrIn
    {
        public int sin_family;
        public uint16 sin_port;
        public PosixExtra.InAddr sin_addr;
    }    
}

