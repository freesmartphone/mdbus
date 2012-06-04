/*
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

using GLib;

public class FsoGsm.GsmDeviceService : FreeSmartphone.GSM.Device, Service
{
    public GsmDeviceService()
    {
    }

    //
    // DBUS (org.freesmartphone.GSM.Device.*)
    //

    public async void get_functionality( out string level, out bool autoregister, out string pin )
        throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.DeviceGetFunctionality>();
        yield m.run();
        level = m.level;
        autoregister = m.autoregister;
        pin = m.pin;
    }

    public async GLib.HashTable<string,GLib.Variant> get_features()
        throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.DeviceGetFeatures>();
        yield m.run();
        return m.features;
    }

    public async bool get_microphone_muted()
        throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.DeviceGetMicrophoneMuted>();
        yield m.run();
        return m.muted;
    }

    public async int get_speaker_volume()
        throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.DeviceGetSpeakerVolume>();
        yield m.run();
        return m.volume;
    }

    public async void set_functionality( string level, bool autoregister, string pin )
        throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        yield modem.setFunctionality( level, autoregister, pin );
    }

    public async void set_microphone_muted( bool muted )
        throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.DeviceSetMicrophoneMuted>();
        yield m.run( muted );
    }

    public async void set_speaker_volume( int volume )
        throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability();
        var m = modem.createMediator<FsoGsm.DeviceSetSpeakerVolume>();
        yield m.run( volume );
    }

    public async FreeSmartphone.GSM.DeviceStatus get_device_status()
        throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        return modem.externalStatus();
    }

}

// vim:ts=4:sw=4:expandtab
