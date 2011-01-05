/*
 * Copyright (C) 2010-2011 Simon Busch <morphis@gravedo.de>
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
 *
 */

namespace Msmcomm
{
    public enum SimPinStatus
    {
        DISABLED,
        ENABLED,
        BLOCKED,
        PERM_BLOCKED,
        CHANGED, // TODO: do we really need this state here?
        UNBLOCKED,
    }
    
    public static class RuntimeData
    {
        public static SimPinStatus pin1_status { get; set; default = SimPinStatus.ENABLED; }
        public static SimPinStatus pin2_status { get; set; default = SimPinStatus.ENABLED; }
        public static SimPinStatus pin1_block_status { get; set; default = SimPinStatus.UNBLOCKED; }
        public static SimPinStatus pin2_block_status { get; set; default = SimPinStatus.UNBLOCKED; }
        public static string current_operator_name { get; set; default = ""; }
        public static int signal_strength { get; set; default = 0; }
        public static Msmcomm.ModemOperationMode functionality_status { get; set; default = ModemOperationMode.UNKNOWN; }
        public static bool block_number { get; set; default = false; }
        public static NetworkRegistrationStatus network_reg_status { get; set; default = NetworkRegistrationStatus.NO_SERVICE; }
        public static NetworkServiceStatus networkServiceStatus { get; set; default = NetworkServiceStatus.NO_SERVICE; }
    }
}

