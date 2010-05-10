[CCode (cprefix = "", lower_case_cprefix = "")]
namespace Posix {
	[CCode (cname = "sethostname", cheader_filename = "unistd.h")]
	public int sethostname(string hostname, ssize_t len);

	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t CBAUD;

	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t CBAUDEX;

	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t ECHOCTL;

	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t ECHOPRT;

	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t ECHOKE;
} // namespace
