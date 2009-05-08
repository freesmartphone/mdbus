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

[CCode (cprefix = "", lower_case_cprefix = "")]
namespace Linux26 {

    [CCode (cprefix = "", lower_case_cprefix = "")]
    namespace Rtc {

        [CCode (cname = "struct rtc_wkalrm", cheader_filename = "linux/rtc.h")]
        public struct WakeAlarm {
            public char enabled;
            public char pending;
            public GLib.Time time;
        }

        [CCode (cheader_filename = "linux/rtc.h,sys/ioctl.h")]
        public const int RTC_RD_TIME;
        [CCode (cheader_filename = "linux/rtc.h,sys/ioctl.h")]
        public const int RTC_SET_TIME;
        [CCode (cheader_filename = "linux/rtc.h,sys/ioctl.h")]
        public const int RTC_WKALM_RD;
        [CCode (cheader_filename = "linux/rtc.h,sys/ioctl.h")]
        public const int RTC_WKALM_SET;
    }

    [CCode (cprefix = "", lower_case_cprefix = "")]
    namespace Netlink {

        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_ROUTE;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_UNUSED;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_USERSOCK;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_FIREWALL;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_INET_DIAG;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_NFLOG;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_XFRM;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_SELINUX;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_ISCSI;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_AUDIT;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_FIB_LOOKUP;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_CONNECTOR;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_NETFILTER;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_IP6_FW;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_DNRTMSG;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_KOBJECT_UEVENT;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_GENERIC;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_SCSITRANSPORT;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_ECRYPTFS;

        // additions to the socket interface
        [CCode (cheader_filename = "sys/socket.h")]
        public const int AF_NETLINK;

        [CCode (cname = "struct sockaddr_nl", cheader_filename = "linux/netlink.h", destroy_function = "")]
        public struct SockAddrNl
        {
            public int nl_family;
            public ushort nl_pad;
            public uint32 nl_pid;
            public uint32 nl_groups;
        }

        /*
        [CCode (cheader_filename = "sys/socket.h", sentinel = "")]
        public int bind (int sockfd, SockAddrNl addr, ulong length );
        */
    }

}
