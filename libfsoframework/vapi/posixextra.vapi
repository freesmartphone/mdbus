/* posixextra.vapi
 *
 * Scheduled for inclusion in posix.vapi
 */

using Posix;

[CCode (cprefix = "", lower_case_cprefix = "")]
namespace PosixExtra {

    /* ------------- select --------------- */

    [CCode (cname = "fd_set", cheader_filename = "sys/select.h", free_function = "")]
    [Compact]
    public struct FdSet
    {
        [CCode (cname = "FD_CLR", instance_pos=1.1)]
        public void clear (int fd);
        [CCode (cname = "FD_ISSET", instance_pos=1.1)]
        public bool isSet (int fd);
        [CCode (cname = "FD_SET", instance_pos=1.1)]
        public void set (int fd);
        [CCode (cname = "FD_ZERO")]
        public void zero ();
    }

    [CCode (cname = "struct timeval", cheader_filename = "time.h", destroy_function = "")]
    public struct TimeVal
    {
        public long tv_sec;
        public long tv_usec;
    }

    /* ------------- pty --------------- */

    [CCode (cheader_filename = "pty.h")]
    public int openpty (out int amaster,
                        out int aslave,
                        [CCode (array_length=false, array_null_terminated=true)] char[] name,
                        termios? termp,
                        WinSize? winp);

    [CCode (cheader_filename = "sys/select.h")]
    public int select (int nfds, FdSet readfds, FdSet writefds, FdSet exceptfds, TimeVal timeval);

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

    /* --------- stdlib --------------- */
    [CCode (cheader_filename = "stdlib.h")]
    public int posix_openpt (int flags);

    [CCode (cheader_filename = "stdlib.h")]
    int ptsname_r (int fd, char[] buf);

    [CCode (cheader_filename = "stdlib.h")]
    public int grantpt (int fd);

    [CCode (cheader_filename = "stdlib.h")]
    public int unlockpt (int fd);

    /* ----------- unistd -------------- */

    [CCode (cheader_filename = "unistd.h")]
    public pid_t getpid ();
    public pid_t getppid ();

    [CCode (cname = "struct winsize", cheader_filename = "termios.h", destroy_function = "")]
    public struct WinSize
    {
        public ushort ws_row;
        public ushort ws_col;
        public ushort ws_xpixel;
        public ushort ws_ypixel;
    }
}

