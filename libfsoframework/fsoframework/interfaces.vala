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

        public const string LedServiceFace = ServiceFacePrefix + ".LED";
        public const string LedServicePath = ServicePathPrefix + "/LED";

        [DBus (name = "org.freesmartphone.Device.LED")]
        public abstract class LED : GLib.Object
        {
            public abstract string GetName();
            public abstract void SetBrightness( int brightness );
            public abstract void SetBlinking( int delay_on, int delay_off ) throws DBus.Error;
            public abstract void SetNetworking( string iface, string mode ) throws DBus.Error;
        }
    }
}
