/* posixextra.vapi
 *
 * Scheduled for inclusion in posix.vapi
 */

using Posix;

[CCode (cprefix = "", lower_case_cprefix = "")]
namespace PosixExtra {

    /* ------------- pty --------------- */

    [CCode (cheader_filename = "pty.h")]
    public int openpty (out int amaster,
                        out int aslave,
                        [CCode (array_length=false, array_null_terminated=true)] char[] name,
                        termios? termp,
                        winsize? winp);

    /* --------- socket --------------- */

    [CCode (cname = "struct in_addr", cheader_filename = "sys/socket.h", destroy_function = "")]
    public struct InAddr
    {
        public uint32 s_addr; /* in_addr_t */
    }

    [CCode (cname = "struct sockaddr_in", cheader_filename = "netinet/in.h", destroy_function = "")]
    public struct SockAddrIn
    {
        public int sin_family;
        public uint16 sin_port;
        public InAddr sin_addr;
    }

    [CCode (cheader_filename = "sys/socket.h")]
    public uint16 htons (uint16 hostshort);

    [CCode (cheader_filename = "sys/socket.h")]
    public uint32 inet_addr (string host); /* in_addr_t */

    [CCode (cheader_filename = "sys/socket.h")]
    public int listen (int s, int backlog);

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

