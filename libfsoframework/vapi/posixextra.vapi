/* posixextra.vapi
 *
 * Scheduled for inclusion in posix.vapi
 */
[CCode (cprefix = "", lower_case_cprefix = "")]
namespace PosixExtra {

    [CCode (cheader_filename = "sys/ioctl.h")]
    public const int TIOCMBIS;

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
                        TermIOs? termp,
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
    public uint32 inet_addr (string host); /* in_addr_t */

    [CCode (cheader_filename = "sys/socket.h")]
    public uint16 htons (uint16 hostshort);

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

    /* ---------------------------- */

	[CCode (cheader_filename = "unistd.h")]
	public int close (int fd);
	[CCode (cheader_filename = "unistd.h")]
	public ssize_t read (int fd, void* buf, size_t count);
	[CCode (cheader_filename = "unistd.h")]
	public ssize_t write (int fd, void* buf, size_t count);

    /* ------------- termios --------------- */

    [CCode (cheader_filename = "termios.h")]
    public const int B0;
    [CCode (cheader_filename = "termios.h")]
    public const int B50;
    [CCode (cheader_filename = "termios.h")]
    public const int B75;
    [CCode (cheader_filename = "termios.h")]
    public const int B110;
    [CCode (cheader_filename = "termios.h")]
    public const int B134;
    [CCode (cheader_filename = "termios.h")]
    public const int B150;
    [CCode (cheader_filename = "termios.h")]
    public const int B200;
    [CCode (cheader_filename = "termios.h")]
    public const int B300;
    [CCode (cheader_filename = "termios.h")]
    public const int B600;
    [CCode (cheader_filename = "termios.h")]
    public const int B1200;
    [CCode (cheader_filename = "termios.h")]
    public const int B1800;
    [CCode (cheader_filename = "termios.h")]
    public const int B2400;
    [CCode (cheader_filename = "termios.h")]
    public const int B4800;
    [CCode (cheader_filename = "termios.h")]
    public const int B9600;
    [CCode (cheader_filename = "termios.h")]
    public const int B19200;
    [CCode (cheader_filename = "termios.h")]
    public const int B38400;
    [CCode (cheader_filename = "termios.h")]
    public const int B57600;
    [CCode (cheader_filename = "termios.h")]
    public const int B115200;
    [CCode (cheader_filename = "termios.h")]
    public const int B230400;
    [CCode (cheader_filename = "termios.h")]
    public const int B460800;
    [CCode (cheader_filename = "termios.h")]
    public const int B500000;
    [CCode (cheader_filename = "termios.h")]
    public const int B576000;
    [CCode (cheader_filename = "termios.h")]
    public const int B921600;
    [CCode (cheader_filename = "termios.h")]
    public const int B1000000;
    [CCode (cheader_filename = "termios.h")]
    public const int B1152000;
    [CCode (cheader_filename = "termios.h")]
    public const int B1500000;
    [CCode (cheader_filename = "termios.h")]
    public const int B2000000;
    [CCode (cheader_filename = "termios.h")]
    public const int B2500000;
    [CCode (cheader_filename = "termios.h")]
    public const int B3000000;
    [CCode (cheader_filename = "termios.h")]
    public const int B3500000;
    [CCode (cheader_filename = "termios.h")]
    public const int B4000000;
    [CCode (cheader_filename = "termios.h")]
    public const int BRKINT;
    [CCode (cheader_filename = "termios.h")]
    public const int CBAUDEX;
    [CCode (cheader_filename = "termios.h")]
    public const int CIBAUD;
    [CCode (cheader_filename = "termios.h")]
    public const int CLOCAL;
    [CCode (cheader_filename = "termios.h")]
    public const int CMSPAR;
    [CCode (cheader_filename = "termios.h")]
    public const int CREAD;
    [CCode (cheader_filename = "termios.h")]
    public const int CRTSCTS;
    [CCode (cheader_filename = "termios.h")]
    public const int CSIZE;
    [CCode (cheader_filename = "termios.h")]
    public const int CS5;
    [CCode (cheader_filename = "termios.h")]
    public const int CS6;
    [CCode (cheader_filename = "termios.h")]
    public const int CS7;
    [CCode (cheader_filename = "termios.h")]
    public const int CS8;
    [CCode (cheader_filename = "termios.h")]
    public const int CSTOPB;
    [CCode (cheader_filename = "termios.h")]
    public const int ECHO;
    [CCode (cheader_filename = "termios.h")]
    public const int ECHOE;
    [CCode (cheader_filename = "termios.h")]
    public const int ECHOK;
    [CCode (cheader_filename = "termios.h")]
    public const int ECHONL;
    [CCode (cheader_filename = "termios.h")]
    public const int ECHOCTL;
    [CCode (cheader_filename = "termios.h")]
    public const int ECHOPRT;
    [CCode (cheader_filename = "termios.h")]
    public const int ECHOKE;
    [CCode (cheader_filename = "termios.h")]
    public const int FLUSHO;
    [CCode (cheader_filename = "termios.h")]
    public const int HUPCL;
    [CCode (cheader_filename = "termios.h")]
    public const int ICANON;
    [CCode (cheader_filename = "termios.h")]
    public const int IGNBRK;
    [CCode (cheader_filename = "termios.h")]
    public const int IGNPAR;
    [CCode (cheader_filename = "termios.h")]
    public const int INPCK;
    [CCode (cheader_filename = "termios.h")]
    public const int ISTRIP;
    [CCode (cheader_filename = "termios.h")]
    public const int ISIG;
    [CCode (cheader_filename = "termios.h")]
    public const int INLCR;
    [CCode (cheader_filename = "termios.h")]
    public const int IGNCR;
    [CCode (cheader_filename = "termios.h")]
    public const int ICRNL;
    [CCode (cheader_filename = "termios.h")]
    public const int IUCLC;
    [CCode (cheader_filename = "termios.h")]
    public const int IXON;
    [CCode (cheader_filename = "termios.h")]
    public const int IXANY;
    [CCode (cheader_filename = "termios.h")]
    public const int IXOFF;
    [CCode (cheader_filename = "termios.h")]
    public const int IMAXBEL;
    [CCode (cheader_filename = "termios.h")]
    public const int IUTF8;
    [CCode (cheader_filename = "termios.h")]
    public const int NOFLSH;
    [CCode (cheader_filename = "termios.h")]
    public const int OCRNL;
    [CCode (cheader_filename = "termios.h")]
    public const int OLCUC;
    [CCode (cheader_filename = "termios.h")]
    public const int ONLCR;
    [CCode (cheader_filename = "termios.h")]
    public const int ONOCR;
    [CCode (cheader_filename = "termios.h")]
    public const int ONLRET;
    [CCode (cheader_filename = "termios.h")]
    public const int OFDEL;
    [CCode (cheader_filename = "termios.h")]
    public const int OFILL;
    [CCode (cheader_filename = "termios.h")]
    public const int OPOST;
    [CCode (cheader_filename = "termios.h")]
    public const int PARMRK;
    [CCode (cheader_filename = "termios.h")]
    public const int PARENB;
    [CCode (cheader_filename = "termios.h")]
    public const int PARODD;
    [CCode (cheader_filename = "termios.h")]
    public const int PENDIN;
    [CCode (cheader_filename = "termios.h")]
    public const int TCIFLUSH;
    [CCode (cheader_filename = "termios.h")]
    public const int TCIOFF;
    [CCode (cheader_filename = "termios.h")]
    public const int TCIOFLUSH;
    [CCode (cheader_filename = "termios.h")]
    public const int TCION;
    [CCode (cheader_filename = "termios.h")]
    public const int TCOOFF;
    [CCode (cheader_filename = "termios.h")]
    public const int TCOON;
    [CCode (cheader_filename = "termios.h")]
    public const int TCOFLUSH;
    [CCode (cheader_filename = "termios.h")]
    public const int TCSANOW;
    [CCode (cheader_filename = "termios.h")]
    public const int TCSADRAIN;
    [CCode (cheader_filename = "termios.h")]
    public const int TCSAFLUSH;
    [CCode (cheader_filename = "termios.h")]
    public const int TIOCM_LE;
    [CCode (cheader_filename = "termios.h")]
    public const int TIOCM_DTR;
    [CCode (cheader_filename = "termios.h")]
    public const int TIOCM_RTS;
    [CCode (cheader_filename = "termios.h")]
    public const int TIOCM_ST;
    [CCode (cheader_filename = "termios.h")]
    public const int TIOCM_SR;
    [CCode (cheader_filename = "termios.h")]
    public const int TIOCM_CTS;
    [CCode (cheader_filename = "termios.h")]
    public const int TIOCM_CARM;
    [CCode (cheader_filename = "termios.h")]
    public const int TIOCM_RNG;
    [CCode (cheader_filename = "termios.h")]
    public const int TIOCM_DSR;
    [CCode (cheader_filename = "termios.h")]
    public const int TIOCM_CD;
    [CCode (cheader_filename = "termios.h")]
    public const int TIOCM_RI;
    [CCode (cheader_filename = "termios.h")]
    public const int TIOCM_OUT1;
    [CCode (cheader_filename = "termios.h")]
    public const int TIOCM_OUT2;
    [CCode (cheader_filename = "termios.h")]
    public const int TIOCM_LOOP;
    [CCode (cheader_filename = "termios.h")]
    public const int TOSTOP;
    [CCode (cheader_filename = "termios.h")]
    public const int VDISCARD;
    [CCode (cheader_filename = "termios.h")]
    public const int VERASE;
    [CCode (cheader_filename = "termios.h")]
    public const int VEOF;
    [CCode (cheader_filename = "termios.h")]
    public const int VEOL;
    [CCode (cheader_filename = "termios.h")]
    public const int VEOL2;
    [CCode (cheader_filename = "termios.h")]
    public const int VINTR;
    [CCode (cheader_filename = "termios.h")]
    public const int VKILL;
    [CCode (cheader_filename = "termios.h")]
    public const int VLNEXT;
    [CCode (cheader_filename = "termios.h")]
    public const int VMIN;
    [CCode (cheader_filename = "termios.h")]
    public const int VQUIT;
    [CCode (cheader_filename = "termios.h")]
    public const int VREPRINT;
    [CCode (cheader_filename = "termios.h")]
    public const int VTIME;
    [CCode (cheader_filename = "termios.h")]
    public const int VSWTC;
    [CCode (cheader_filename = "termios.h")]
    public const int VSTART;
    [CCode (cheader_filename = "termios.h")]
    public const int VSTOP;
    [CCode (cheader_filename = "termios.h")]
    public const int VSUSP;
    [CCode (cheader_filename = "termios.h")]
    public const int VWERASE;

    [CCode (cname = "struct termios", cheader_filename = "termios.h", destroy_function = "")]
    public struct TermIOs
    {
        public uint c_iflag;
        public uint c_oflag;
        public uint c_cflag;
        public uint c_lflag;
        public uchar c_line;
        public uchar[32] c_cc;
        public uint c_ispeed;
        public uint c_ospeed;
    }
    [CCode (cname = "struct winsize", cheader_filename = "termios.h", destroy_function = "")]
    public struct WinSize
    {
        public ushort ws_row;
        public ushort ws_col;
        public ushort ws_xpixel;
        public ushort ws_ypixel;
    }
    [CCode (cheader_filename = "termios.h")]
    public void cfmakeraw (TermIOs termios_p);

    [CCode (cheader_filename = "termios.h")]
    public uint cfgetispeed (TermIOs termios_p);

    [CCode (cheader_filename = "termios.h")]
    public uint cfgetospeed (TermIOs termios_p);

    [CCode (cheader_filename = "termios.h")]
    public int cfsetispeed (TermIOs termios_p, uint speed);

    [CCode (cheader_filename = "termios.h")]
    public int cfsetospeed (TermIOs termios_p, uint speed);

    [CCode (cheader_filename = "termios.h")]
    public int cfsetspeed (TermIOs termios_p, uint speed);

    [CCode (cheader_filename = "termios.h")]
    public int tcdrain (int fd);

    [CCode (cheader_filename = "termios.h")]
    public int tcflush (int fd, int queue_selector);

    [CCode (cheader_filename = "termios.h")]
    public int tcgetattr (int fd, TermIOs termios_p);

    [CCode (cheader_filename = "termios.h")]
    public int tcsetattr (int fd, int optional_actions, TermIOs termios_p);

    [CCode (cheader_filename = "termios.h")]
    public int tcsendbreak (int fd, int duration);

    [CCode (cheader_filename = "termios.h")]
    public int tcflow (int fd, int action);

    /* ------------- unistd --------------- */
    [CCode (cheader_filename = "unistd.h")]
    int ttyname_r (int fd, char[] buf);

    [CCode (cheader_filename = "unistd.h")]
    uint sleep (uint seconds);


}

