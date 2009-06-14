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

// NOTE: This file only contains object paths and interface names.
// The actual interfaces are implemented in libfso-glib.

namespace FsoFramework
{
    public const string ServiceDBusPrefix = "org.freesmartphone";
    public const string ServicePathPrefix = "/org/freesmartphone";
    public const string ServiceFacePrefix = "org.freesmartphone";

    namespace Device
    {
        public const string ServiceDBusName = FsoFramework.ServiceDBusPrefix + ".odeviced";

        public const string ServiceFacePrefix = FsoFramework.ServiceFacePrefix + ".Device";
        public const string ServicePathPrefix = FsoFramework.ServicePathPrefix + "/Device";

        public const string AudioServiceFace = ServiceFacePrefix + ".Audio";
        public const string AudioServicePath = ServicePathPrefix + "/Audio";

        public const string DisplayServiceFace = ServiceFacePrefix + ".Display";
        public const string DisplayServicePath = ServicePathPrefix + "/Display";

        public const string IdleNotifierServiceFace = ServiceFacePrefix + ".IdleNotifier";
        public const string IdleNotifierServicePath = ServicePathPrefix + "/IdleNotifier";

        public const string InfoServiceFace = ServiceFacePrefix + ".Info";
        public const string InfoServicePath = ServicePathPrefix + "/Info";

        public const string InputServiceFace = ServiceFacePrefix + ".Input";
        public const string InputServicePath = ServicePathPrefix + "/Input";

        public const string LedServiceFace = ServiceFacePrefix + ".LED";
        public const string LedServicePath = ServicePathPrefix + "/LED";

        public const string PowerControlServiceFace = ServiceFacePrefix + ".PowerControl";
        public const string PowerControlServicePath = ServicePathPrefix + "/PowerControl";

        public const string PowerSupplyServiceFace = ServiceFacePrefix + ".PowerSupply";
        public const string PowerSupplyServicePath = ServicePathPrefix + "/PowerSupply";

        public const string RtcServiceFace = ServiceFacePrefix + ".RTC";
        public const string RtcServicePath = ServicePathPrefix + "/RTC";
    }

    namespace Network
    {
        public const string ServiceDBusName = FsoFramework.ServiceDBusPrefix + ".onetworkd";

        public const string ServiceFacePrefix = FsoFramework.ServiceFacePrefix + ".Network";
        public const string ServicePathPrefix = FsoFramework.ServicePathPrefix + "/Network";
    }

    namespace Resource
    {
        public const string ServiceDBusName = FsoFramework.ServiceDBusPrefix + ".oresourced"; // dummy

        public const string ServiceFacePrefix = FsoFramework.ServiceFacePrefix + ".Resource";
        public const string ServicePathPrefix = FsoFramework.ServicePathPrefix + "/Resource";
    }

    namespace Time
    {
        public const string ServiceDBusName = FsoFramework.ServiceDBusPrefix + ".otimed";

        public const string ServiceFacePrefix = FsoFramework.ServiceFacePrefix + ".Time";
        public const string ServicePathPrefix = FsoFramework.ServicePathPrefix + "/Time";

        public const string AlarmServiceFace = ServiceFacePrefix + ".Alarm";
        public const string AlarmServicePath = ServicePathPrefix + "/Alarm";
    }

    namespace Usage
    {
        public const string ServiceDBusName = FsoFramework.ServiceDBusPrefix + ".ousaged";

        public const string ServiceFacePrefix = FsoFramework.ServiceFacePrefix + ".Usage";
        public const string ServicePathPrefix = FsoFramework.ServicePathPrefix + "/Usage";
    }
}
