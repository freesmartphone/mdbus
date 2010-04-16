/*
 * Copyright (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

    namespace Data
    {
        public const string ServiceDBusName = FsoFramework.ServiceDBusPrefix + ".odatad";

        public const string ServiceFacePrefix = FsoFramework.ServiceFacePrefix + ".Data";
        public const string ServicePathPrefix = FsoFramework.ServicePathPrefix + "/Data";

        public const string WorldServiceFace = ServiceFacePrefix + ".World";
        public const string WorldServicePath = ServicePathPrefix + "/World";
    }

    namespace Device
    {
        public const string ServiceDBusName = FsoFramework.ServiceDBusPrefix + ".odeviced";

        public const string ServiceFacePrefix = FsoFramework.ServiceFacePrefix + ".Device";
        public const string ServicePathPrefix = FsoFramework.ServicePathPrefix + "/Device";

        public const string AmbientLightServiceFace = ServiceFacePrefix + ".AmbientLight";
        public const string AmbientLightServicePath = ServicePathPrefix + "/AmbientLight";

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

        public const string OrientationServiceFace = ServiceFacePrefix + ".Orientation";
        public const string OrientationServicePath = ServicePathPrefix + "/Orientation";

        public const string PowerControlServiceFace = ServiceFacePrefix + ".PowerControl";
        public const string PowerControlServicePath = ServicePathPrefix + "/PowerControl";

        public const string PowerSupplyServiceFace = ServiceFacePrefix + ".PowerSupply";
        public const string PowerSupplyServicePath = ServicePathPrefix + "/PowerSupply";

        public const string ProximityServiceFace = ServiceFacePrefix + ".Proximity";
        public const string ProximityServicePath = ServicePathPrefix + "/Proximity";

        public const string RtcServiceFace = ServiceFacePrefix + ".RTC";
        public const string RtcServicePath = ServicePathPrefix + "/RTC";

        public const string VibratorServiceFace = ServiceFacePrefix + ".Vibrator";
        public const string VibratorServicePath = ServicePathPrefix + "/Vibrator";
    }

    namespace GPS
    {
        public const string ServiceDBusName = FsoFramework.ServiceDBusPrefix + ".ogpsd";

        public const string ServiceFacePrefix = FsoFramework.ServiceFacePrefix + ".GPS";
        public const string ServicePathPrefix = FsoFramework.ServicePathPrefix + "/GPS";

        public const string DeviceServiceFace = ServiceFacePrefix + ".Device";
        public const string DeviceServicePath = ServicePathPrefix + "/Device";
    }

    namespace GSM
    {
        public const string ServiceDBusName = FsoFramework.ServiceDBusPrefix + ".ogsmd";

        public const string ServiceFacePrefix = FsoFramework.ServiceFacePrefix + ".GSM";
        public const string ServicePathPrefix = FsoFramework.ServicePathPrefix + "/GSM";

        public const string DeviceServiceFace = ServiceFacePrefix + ".Device";
        public const string DeviceServicePath = ServicePathPrefix + "/Device";
    }

    namespace Network
    {
        public const string ServiceDBusName = FsoFramework.ServiceDBusPrefix + ".onetworkd";

        public const string ServiceFacePrefix = FsoFramework.ServiceFacePrefix + ".Network";
        public const string ServicePathPrefix = FsoFramework.ServicePathPrefix + "/Network";
    }

    namespace MusicPlayer
    {
        public const string ServiceDBusName = FsoFramework.ServiceDBusPrefix + ".omusicd";

        public const string ServiceFacePrefix = FsoFramework.ServiceFacePrefix + ".MusicPlayer";
        public const string ServicePathPrefix = FsoFramework.ServicePathPrefix + "/MusicPlayer";

        public const string PlaylistServiceFace = ServiceFacePrefix + ".Playlist";
        public const string PlaylistServicePathPrefix = ServicePathPrefix + "/Playlists";
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

    namespace Preferences
    {
        public const string ServiceDBusName = FsoFramework.ServiceDBusPrefix + ".opreferencesd";

	public const string ServiceFacePrefix = FsoFramework.ServiceFacePrefix + ".Preferences";
	public const string ServicePathPrefix = FsoFramework.ServicePathPrefix + "/Preferences";
    }

    namespace PIM
    {
        public const string ServiceDBusName = FsoFramework.ServiceDBusPrefix + ".opimd";

	public const string ServiceFacePrefix = FsoFramework.ServiceFacePrefix + ".PIM";
	public const string ServicePathPrefix = FsoFramework.ServicePathPrefix + "/PIM";

	public const string MessagesServiceFace = ServiceFacePrefix + ".Messages";
	public const string MessagesServicePath = ServicePathPrefix + "/Messages";

	public const string ContactsServiceFace = ServiceFacePrefix + ".Contacts";
	public const string ContactsServicePath = ServicePathPrefix + "/Contacts";

	public const string CallsServiceFace = ServiceFacePrefix + ".Calls";
	public const string CallsServicePath = ServicePathPrefix + "/Calls";

	public const string TasksServiceFace = ServiceFacePrefix + ".Tasks";
	public const string TasksServicePath = ServicePathPrefix + "/Tasks";

	public const string NotesServiceFace = ServiceFacePrefix + ".Notes";
	public const string NotesServicePath = ServicePathPrefix + "/Notes";
    }

}
