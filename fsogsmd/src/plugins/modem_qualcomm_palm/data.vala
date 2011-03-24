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
        pin_status = MsmPinStatus.DISABLED;
        operation_mode = Msmcomm.OperationMode.OFFLINE;
        sim_available = false;
        sim_auth_status = FreeSmartphone.GSM.SIMAuthStatus.UNKNOWN;
        network_info = NetworkInfo();
        network_info.reset();
    }

    public static MsmPinStatus pin_status;
    public static FreeSmartphone.GSM.SIMAuthStatus sim_auth_status;
    public static Msmcomm.OperationMode operation_mode;
    public static bool sim_available;

    public struct NetworkInfo
    {
        Msmcomm.NetworkRegistrationStatus reg_status;
        Msmcomm.NetworkServiceStatus service_status;
        public string operator_name;
        public uint rssi;
        public uint ecio;

        public void reset()
        {
            reg_status = Msmcomm.NetworkRegistrationStatus.NO_SERVICE;
            service_status = Msmcomm.NetworkServiceStatus.NO_SERVICE;
            operator_name = "";
            rssi = 0;
            ecio = 0;
        }
    }

    public static NetworkInfo network_info;
}

