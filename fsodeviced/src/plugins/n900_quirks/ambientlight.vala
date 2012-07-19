/*
 * Copyright (C) 2011-2012 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

using GLib;

namespace AmbientLight
{
    internal const string DEFAULT_NODE = "class/i2c-adapter/i2c-2/2-0029/";
    internal const int DARKNESS = 0;
    internal const int SUNLIGHT = 100;

    public class N900 : FreeSmartphone.Device.AmbientLight, FsoFramework.AbstractObject
    {
        FsoFramework.Subsystem subsystem;

        private string sysfsnode;
        private string luxnode;

        private int maxvalue;
        private int minvalue;

        public N900( FsoFramework.Subsystem subsystem, string sysfsnode )
        {
            minvalue = DARKNESS;
            maxvalue = SUNLIGHT;

            this.subsystem = subsystem;
            this.sysfsnode = sysfsnode;

            this.luxnode = sysfsnode + "/lux";
            if ( !FsoFramework.FileHandling.isPresent( this.luxnode ) )
            {
                logger.error( @"Sysfs class is damaged, missing $(this.luxnode); skipping." );
                return;
            }

            subsystem.registerObjectForServiceWithPrefix<FreeSmartphone.Device.AmbientLight>( FsoFramework.Device.ServiceDBusName,
                FsoFramework.Device.AmbientLightServicePath, this );

            logger.info( "Created" );
        }

        public override string repr()
        {
            return @"<$sysfsnode>";
        }

        private int _valueToPercent( int value )
        {
            double v = value;
            return (int)(100.0 / (maxvalue-minvalue) * (v-minvalue));
        }

        //
        // FreeSmartphone.Device.AmbientLight (DBUS API)
        //
        public async void get_ambient_light_brightness( out int brightness, out int timestamp ) throws FreeSmartphone.Error, DBusError, IOError
        {
            var lux = FsoFramework.FileHandling.read( this.luxnode ).to_int();
            //brightness = _valueToPercent( lux );
            brightness = lux;
            var t = (int) time_t();
            timestamp = t;
        }
    }
} /* namespace */

// vim:ts=4:sw=4:expandtab
