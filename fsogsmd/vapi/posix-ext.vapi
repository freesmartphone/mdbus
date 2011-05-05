namespace Posix
{
	[CCode (cheader_filename = "arpa/inet.h")]
	string inet_ntop (int af, void* src, uint8[] dst);
}

// vim:ts=4:sw=4:expandtab
