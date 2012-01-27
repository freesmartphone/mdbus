/**
 * (C) 2011 Simon Busch <morphis@gravedo.de>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 **/

namespace Samsung
{
    [CCode (cname = "int", has_type_id = false, cprefix = "IOCTL_MODEM_", cheader_filename = "samsung_modem_ctl.h")]
    public enum ModemIoctlType
    {
        SEND,
        RECV,
        RAMDUMP,
        RESET,
        START,
        OFF,
    }

    [Compact]
    [CCode (cname = "struct modem_io", cheader_filename = "crespo_modem_ctl.h", destroy_function = "")]
    public struct ModemData
    {
        public uint32 size;
        public uint32 id;
        public uint32 cmd;
        [CCode (array_length_cname = "size")]
        public uint8[] data;
    }
}
