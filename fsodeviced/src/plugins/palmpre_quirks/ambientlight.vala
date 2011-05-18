/*
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

class PalmPre.AmbientLight : FreeSmartphone.Device.AmbientLight, FsoFramework.AbstractObject
{
    internal const string DEFAULT_INPUT_NODE = "input/event4";
    internal const int DARKNESS = 0;
    internal const int SUNLIGHT = 1000;

    FsoFramework.Subsystem subsystem;

    private string sysfsnode;
    private string resultnode;
    private string averagenode;
    private string pollintervalnode;

    private int maxvalue;
    private int minvalue;
    private long start_timestamp;
    private int brightness_timestamp = -1;
    private int _brightness = -1;
    private int brightness {
        get {return _brightness; }
        set {
            if(brightness != value) {
                _brightness = value;
                ambient_light_brightness(brightness);
            }
            TimeVal tv = TimeVal();
            tv.get_current_time();
            brightness_timestamp = (int)(tv.tv_sec - start_timestamp);
        }
    }

    FsoFramework.Async.ReactorChannel input;

    public AmbientLight( FsoFramework.Subsystem subsystem, string sysfsnode )
    {
        minvalue = DARKNESS;
        maxvalue = SUNLIGHT;

        this.subsystem = subsystem;
        this.sysfsnode = sysfsnode;

        this.resultnode = sysfsnode + "/result";
        this.averagenode = sysfsnode + "/average";
        this.pollintervalnode = sysfsnode + "/poll_interval";

        if ( !FsoFramework.FileHandling.isPresent( this.resultnode ) )
        {
            logger.error( @"Sysfs class is damaged, missing $(this.resultnode); skipping." );
            return;
        }

        var fd = Posix.open( GLib.Path.build_filename( devfs_root, DEFAULT_INPUT_NODE ), Posix.O_RDONLY );
        if ( fd == -1 )
        {
            logger.error( @"Can't open $devfs_root/$DEFAULT_INPUT_NODE: $(Posix.strerror(Posix.errno))" );
            return;
        }

        input = new FsoFramework.Async.ReactorChannel( fd, onInputEvent, sizeof( Linux.Input.Event ) );

        subsystem.registerObjectForServiceWithPrefix<FreeSmartphone.Device.AmbientLight>( FsoFramework.Device.ServiceDBusName, FsoFramework.Device.AmbientLightServicePath, this );

        logger.info( "Created" );
    }

    public override string repr()
    {
        return @"<$sysfsnode>";
    }

    private void onInputEvent( void* data, ssize_t length )
    {
        var event = (Linux.Input.Event*) data;
        if ( event->type != 3 || event->code != 40 )
        {
            return;
        }
        brightness = _valueToPercent( event->value);
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
        brightness = this.brightness;
        timestamp = brightness_timestamp;
    }
}

// vim:ts=4:sw=4:expandtab
