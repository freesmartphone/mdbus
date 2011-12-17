/* asound.vapi
 *
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

[CCode (lower_case_cprefix = "snd_", cheader_filename = "alsa/asoundlib.h")]
namespace Alsa {


    [Compact]
    [CCode (cprefix = "snd_ctl_elem_id_", cname = "snd_ctl_elem_id_t", free_function = "snd_ctl_elem_id_free")]
    public class ElemIdExt : ElemId
    {
        [CCode (cname = "snd_ctl_elem_id_malloc")]
        public static int alloc (out ElemIdExt eid);

        public unowned string get_name();
        public uint get_numid();
        public uint get_index();
        public uint get_device();
        public uint get_subdevice();
        //public unowned string get_name();

        public void set_numid( uint numid );
        public void set_index( uint index );
        public void set_name( string name );
        public void set_device( uint device );
        public void set_subdevice( uint subdevice );
        public void set_interface( ElemInterface interface );
    }

    [CCode (cname = "snd_card_get_name")]
    public int getName( int idx, out string name );
}

// vim:ts=4:sw=4:expandtab
