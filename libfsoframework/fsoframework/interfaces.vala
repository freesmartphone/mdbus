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

// NOTE: This file is only temporarily. It will be replaced with libfso-glib,
// which are generated interfaces from actual spec files.

namespace FsoFramework
{
    public const string ServiceDBusPrefix = "org.freesmartphone";
    public const string ServicePathPrefix = "/org/freesmartphone";
    public const string ServiceFacePrefix = "org.freesmartphone";

    // generic errors
    [DBus (name = "org.freesmartphone")]
    public errordomain OrgFreesmartphone
    {
        [DBus (name = "Unsupported")]
        Unsupported,
        [DBus (name = "InvalidParameter")]
        InvalidParameter,
        [DBus (name = "SystemError")]
        SystemError
    }

    namespace Device
    {
        public const string ServiceDBusName = FsoFramework.ServiceDBusPrefix + ".odeviced";

        public const string ServiceFacePrefix = FsoFramework.ServiceFacePrefix + ".Device";
        public const string ServicePathPrefix = FsoFramework.ServicePathPrefix + "/Device";

        public const string DisplayServiceFace = ServiceFacePrefix + ".Display";
        public const string DisplayServicePath = ServicePathPrefix + "/Display";

        public const string InfoServiceFace = ServiceFacePrefix + ".Info";
        public const string InfoServicePath = ServicePathPrefix + "/Info";

        public const string LedServiceFace = ServiceFacePrefix + ".LED";
        public const string LedServicePath = ServicePathPrefix + "/LED";

        public const string PowerSupplyServiceFace = ServiceFacePrefix + ".PowerSupply";
        public const string PowerSupplyServicePath = ServicePathPrefix + "/PowerSupply";

        public const string RtcServiceFace = ServiceFacePrefix + ".RTC";
        public const string RtcServicePath = ServicePathPrefix + "/RTC";

        [DBus (name = "org.freesmartphone.Device.Display")]
        public abstract interface Display : GLib.Object
        {
            public abstract void SetBrightness(int brightness) throws DBus.Error;
            public abstract int GetBrightness() throws DBus.Error;
            public abstract bool GetBacklightPower() throws DBus.Error;
            public abstract void SetBacklightPower(bool power) throws DBus.Error;
            public abstract HashTable<string, Value?> GetInfo() throws DBus.Error;
        }

        [DBus (name = "org.freesmartphone.Device.Info")]
        public abstract interface Info : GLib.Object
        {
            public abstract HashTable<string, Value?> GetCpuInfo() throws DBus.Error;
        }

        [DBus (name = "org.freesmartphone.Device.LED")]
        public abstract interface LED : GLib.Object
        {
            public abstract string GetName() throws DBus.Error;
            public abstract void SetBrightness( int brightness ) throws DBus.Error;
            public abstract void SetBlinking( int delay_on, int delay_off ) throws OrgFreesmartphone, DBus.Error;
            public abstract void SetNetworking( string iface, string mode ) throws OrgFreesmartphone, DBus.Error;
        }

        [DBus (name = "org.freesmartphone.Device.PowerSupply")]
        public abstract interface PowerSupply : GLib.Object
        {
            public abstract string GetName() throws DBus.Error;
            public abstract string GetPowerStatus() throws DBus.Error;
            public signal void PowerStatus( string power_status );
            public abstract int GetCapacity() throws DBus.Error;
            public signal void Capacity( int capacity );
        }

        [DBus (name = "org.freesmartphone.Device.RTC")]
        public abstract interface RTC : GLib.Object
        {
            public abstract string GetName() throws DBus.Error;
            public abstract int GetCurrentTime() throws OrgFreesmartphone, DBus.Error;
            public abstract void SetCurrentTime( int seconds_since_epoch ) throws OrgFreesmartphone, DBus.Error;
            public abstract int GetWakeupTime() throws OrgFreesmartphone, DBus.Error;
            public abstract void SetWakeupTime( int seconds_since_epoch ) throws OrgFreesmartphone, DBus.Error;
        }

    }
}
