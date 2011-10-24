/*
 * Copyright (C) 2011 Simon Busch <morphis@gravedo.de>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 */

using SamsungIpc;

namespace Samsung
{
    public static class ModemState
    {
        public static uint8 power_state = 0;

        public static uint8 sim_icc_type = 0;
        public static Security.SimStatus sim_status = Security.SimStatus.INITIALIZING;

        public static uint8 network_signal_strength = 0;
        public static uint16 network_lac = 0;
        public static uint32 network_cid = 0;
        public static Network.RegistrationState network_reg_state = Network.RegistrationState.NONE;
        public static Network.AccessTechnology network_act = Network.AccessTechnology.UNKNOWN;
        public static string network_plmn = "unknown";
    }
}
