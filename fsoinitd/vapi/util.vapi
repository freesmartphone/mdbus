
[CCode (cprefix = "", lower_case_cprefix = "")]
namespace Posix {
	[CCode (cname = "sethostname", cheader_filename = "unistd.h")]
	public int sethostname(string hostname, ssize_t len);
} // namespace
