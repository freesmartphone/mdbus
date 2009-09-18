/**
 * Copyright (C) 2009 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 */

/**
 * NOTE: Scheduled for inclusion in posix.vapi
 */

using Posix;

[CCode (cprefix = "", lower_case_cprefix = "")]
namespace PosixExtra {

    [CCode (cheader_filename = "arpa/inet.h")]
    public uint32 inet_addr (string host);
    [CCode (cheader_filename = "arpa/inet.h")]
    public int inet_aton(string cp, out InAddr addr);
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

    /* ------------- netdb --------------- */


    [CCode (cname = "struct hostent", cheader_filename = "netdb.h")]
    public class HostEnt {
        public string h_name;
        [CCode (array_length=false, array_null_terminated=true)]
        public string[] h_aliases;
        public int h_addrtype;
        public int h_length;
        [CCode (array_length=false, array_null_terminated=true)]
        public string[] h_addr_list;
    }

    [CCode (cheader_filename = "netdb.h")]
    public unowned HostEnt gethostbyname (string name);

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
    [CCode (cheader_filename = "sys/socket.h", sentinel = "")]
    public int accept (int sfd, ... );
    [CCode (cheader_filename = "sys/socket.h",  sentinel = "")]
    public int connect(int sfd, ... );

    /* ----------- unistd -------------- */

    [CCode (cname = "struct winsize", cheader_filename = "termios.h", destroy_function = "")]
    public struct winsize
    {
        public ushort ws_row;
        public ushort ws_col;
        public ushort ws_xpixel;
        public ushort ws_ypixel;
    }

    [CCode (cheader_filename = "unistd.h")]
    public int nice (int inc);

}
