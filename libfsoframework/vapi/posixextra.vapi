/* posixextra.vapi
 *
 * Scheduled for inclusion in posix.vapi
 */

using Posix;

[CCode (cprefix = "", lower_case_cprefix = "")]
namespace PosixExtra {

    [CCode (cheader_filename = "arpa/inet.h")]
    public uint32 inet_addr (string host);
    [CCode (cheader_filename = "arpa/inet.h")]
    public weak string inet_ntoa (InAddr addr);
    [CCode (cheader_filename = "arpa/inet.h")]
    public uint32 htonl (uint32 hostlong);
    [CCode (cheader_filename = "arpa/inet.h")]
    public uint32 ntohl (uint32 netlong);
    [CCode (cheader_filename = "arpa/inet.h")]
    public uint16 htons (uint16 hostshort);
    [CCode (cheader_filename = "arpa/inet.h")]
    public uint16 ntohs (uint16 netshort);


    /* ------------- pty --------------- */

    [CCode (cheader_filename = "pty.h")]
    public int openpty (out int amaster,
                        out int aslave,
                        [CCode (array_length=false, array_null_terminated=true)] char[] name,
                        termios? termp,
                        winsize? winp);

    /* --------- socket --------------- */

    [SimpleType]
    [CCode (cname = "struct in_addr", cheader_filename = "sys/socket.h", destroy_function = "")]
    public struct InAddr {
        public uint32 s_addr;
    }

    [CCode (cname = "struct sock_addr", cheader_filename = "sys/socket.h", destroy_function = "")]
    public struct SockAddr {
    }

    [CCode (cname = "struct sockaddr_in", cheader_filename = "netinet/in.h", destroy_function = "")]
    public struct SockAddrIn
    {
        public int sin_family;
        public uint16 sin_port;
        public InAddr sin_addr;
    }

    [IntegerType]
    [CCode (cname = "socklen_t", cheader_filename = "sys/socket.h", default_value = "0")]
    public struct socklen_t {
    }

    [CCode (cheader_filename = "sys/socket.h")]
    public int listen (int sfd, int backlog);
    [CCode (cheader_filename = "sys/socket.h")]
    public int accept (int sfd, SockAddr addr, ref socklen_t addrlen );

    /* ----------- unistd -------------- */

    [CCode (cname = "struct winsize", cheader_filename = "termios.h", destroy_function = "")]
    public struct winsize
    {
        public ushort ws_row;
        public ushort ws_col;
        public ushort ws_xpixel;
        public ushort ws_ypixel;
    }
}

