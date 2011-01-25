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

public enum MsmPinStatus
{
    DISABLED,
    ENABLED,
    BLOCKED,
    PERM_BLOCKED,
}

/**
 * Holds data comming from the modem through various urc messages. Most of this fields are
 * only accessible through the incomming urc messages so we have the save it at some place
 * for later access.
 **/
public static class MsmData
{
    public static void reset()
    {
        pin1_status = MsmPinStatus.ENABLED;
        pin2_status = MsmPinStatus.ENABLED;
        operation_mode = Msmcomm.OperationMode.OFFLINE;
        network_info = NetworkInfo();
        network_info.reg_status = Msmcomm.NetworkRegistrationStatus.NO_SERVICE;
        network_info.service_status = Msmcomm.NetworkServiceStatus.NO_SERVICE;
        network_info.operator_name = "";
        network_info.rssi = 0;
        network_info.ecio = 0;
    }

    public static MsmPinStatus pin1_status;
    public static MsmPinStatus pin2_status;
    public static Msmcomm.OperationMode operation_mode;

    public struct NetworkInfo
    {
        Msmcomm.NetworkRegistrationStatus reg_status;
        Msmcomm.NetworkServiceStatus service_status;
        public string operator_name;
        public uint rssi;
        public uint ecio;
    }

    public static NetworkInfo network_info;
}

