// scheduled for mainline inclusion

[CCode (cprefix = "", lower_case_cprefix = "")]
namespace Linux {

	public Posix.pid_t gettid()
	{
		return (Posix.pid_t) Linux.syscall( Linux.SysCall.gettid );
	}

	[CCode (cprefix = "SYS_", cname = "int")]
	public enum SysCall {
		gettid
	}

	[CCode (cname = "syscall", cheader_filename = "unistd.h,sys/syscall.h")]
	public int syscall (int number, ...);
}
