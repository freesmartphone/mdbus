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
}

// vim:ts=4:sw=4:expandtab
