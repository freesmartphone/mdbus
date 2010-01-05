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

using GLib;

namespace Kernel26
{

/**
 * Magic ioctl constants for RTC.
 **/
public const uint IOCTL_RTC_RD_TIME = (uint)0x80247009;
public const uint IOCTL_RTC_SET_TIME = 0x4024700a;
public const uint IOCTL_RTC_WKALM_RD = (uint)0x80287010;
public const uint IOCTL_RTC_WKALM_SET = 0x4028700f;

/**
 * Implementation of org.freesmartphone.Device.RTC for the Kernel26 Real-Time-Clock interface
 **/
class Rtc : FreeSmartphone.Device.RealtimeClock, FsoFramework.AbstractObject
{
    FsoFramework.Subsystem subsystem;

    private string sysfsnode;
    private string devnode;
    private int rtc_fd;
    private IOChannel channel;
    private uint watch;
    private static uint counter;

    public Rtc( FsoFramework.Subsystem subsystem, string sysfsnode )
    {
        this.subsystem = subsystem;
        this.sysfsnode = sysfsnode;
        this.devnode = sysfsnode.replace( "/sys/class/rtc/", "/dev/" );

        subsystem.registerServiceName( FsoFramework.Device.ServiceDBusName );
        subsystem.registerServiceObject( FsoFramework.Device.ServiceDBusName,
                                         "%s/%u".printf( FsoFramework.Device.RtcServicePath, counter++ ),
                                         this );

        rtc_fd = -1;
        logger.info( "Created new Rtc object." );
    }

    public override string repr()
    {
        return "<FsoFramework.Device.Rtc @ %s : %s>".printf( sysfsnode, devnode );
    }

    private void openRtc() throws FreeSmartphone.Error
    {
        if ( channel == null ) // not waiting for any alarm
        {
            rtc_fd = Posix.open( this.devnode, Posix.O_RDONLY );
            if ( rtc_fd == -1 )
            {
                throw new FreeSmartphone.Error.SYSTEM_ERROR( Posix.strerror( Posix.errno ) );
            }
        }
    }

    private void closeRtc( bool raise = false ) throws FreeSmartphone.Error
    {
        var e = @"$(Posix.strerror(Posix.errno))";
        if ( channel == null && rtc_fd != -1 ) // not waiting for any alarm, rtc opened
        {
            Posix.close( rtc_fd );
        }
        if ( raise )
        {
            throw new FreeSmartphone.Error.SYSTEM_ERROR( e );
        }
    }

    private bool onInputEvent( IOChannel source, IOCondition condition )
    {
        if ( source != channel )
        {
            logger.error( "Bogus onInputEvent for RTC channel" );
        }
        else
        {
            var buf = new char[1024];
            var bytesread = Posix.read( source.unix_get_fd(), buf, 1024 );
            if ( bytesread == 0 )
            {
                logger.warning( "Could not read from input device fd %d.".printf( source.unix_get_fd() ) );
            }
            else
            {
                logger.debug( "Read %d bytes from RTC".printf( (int)bytesread ) );
            }
        }
        set_wakeup_time( 0 ); // disable
        var now = TimeVal();
        this.alarm( (int)now.tv_sec ); // DBUS SIGNAL
        return false; // don't call again
    }

    private int _getCurrentTime() throws FreeSmartphone.Error
    {
        openRtc();
        GLib.Time t = {};
        var res = Posix.ioctl( rtc_fd, Linux.Rtc.RTC_RD_TIME, &t );
        closeRtc( res == -1 );
        logger.info( "RTC time equals %s".printf( t.to_string() ) );
        return (int)Linux.timegm( t );
    }

    //
    // FreeSmartphone.Device.RealtimeClock (DBUS API)
    //
    public async string get_name() throws DBus.Error
    {
        return Path.get_basename( sysfsnode );
    }

    public async int get_current_time() throws FreeSmartphone.Error, DBus.Error
    {
        return _getCurrentTime();
    }

    public async void set_current_time( int seconds_since_epoch ) throws FreeSmartphone.Error, DBus.Error
    {
        openRtc();
        var t = GLib.Time.gm( (time_t) seconds_since_epoch ); // VALABUG: cast is necessary here, otherwise things go havoc
        logger.info( "Setting RTC time to %s (dst=%d)".printf( t.to_string(), t.isdst ) );
        var res = Posix.ioctl( rtc_fd, Linux.Rtc.RTC_SET_TIME, &t );
        closeRtc( res == -1 );
    }

    public async int get_wakeup_time() throws FreeSmartphone.Error, DBus.Error
    {
        openRtc();
        Linux.Rtc.WakeAlarm alarm = {};
        var res = Posix.ioctl( rtc_fd, Linux.Rtc.RTC_WKALM_RD, &alarm );
        closeRtc( res == -1 );
        GLib.Time t = {};
        t.second = alarm.time.tm_sec;
        t.minute = alarm.time.tm_min;
        t.hour = alarm.time.tm_hour;
        t.day = alarm.time.tm_mday;
        t.month = alarm.time.tm_mon;
        t.year = alarm.time.tm_year;
        //t.isdst = alarm.time.tm_isdst;

        logger.info( "RTC alarm equals %s. Enabled=%s, Pending=%s".printf( t.to_string(), ((bool)alarm.enabled).to_string(), ((bool)alarm.pending).to_string() ) );

        return ( alarm.enabled == 1 ) ? (int) Linux.timegm( t ) : 0;
    }

    public async void set_wakeup_time( int seconds_since_epoch ) throws FreeSmartphone.Error, DBus.Error
    {
        var rtctime = _getCurrentTime();
        if ( seconds_since_epoch > 0 && rtctime >= seconds_since_epoch )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "RTC Wakeup time not in the future" );
        }
        Linux.Rtc.WakeAlarm alarm = {};
        var t = GLib.Time.gm( (time_t) seconds_since_epoch );

        logger.info( "Setting RTC alarm to %s (dst=%d)".printf( t.to_string(), t.isdst ) );

        alarm.time.tm_sec = t.second;
        alarm.time.tm_min = t.minute;
        alarm.time.tm_hour = t.hour;
        alarm.time.tm_mday = t.day;
        alarm.time.tm_mon = t.month;
        alarm.time.tm_year = t.year;
        //alarm.time.tm_isdst = t.isdst;

        alarm.enabled = seconds_since_epoch > 0 ? 1 : 0;
        alarm.pending = 0;

        openRtc();
        var res = Posix.ioctl( rtc_fd, Linux.Rtc.RTC_WKALM_SET, &alarm );
        if ( res == -1 )
        {
            closeRtc( true );
        }
        if ( alarm.enabled == 1 )
        {
            if ( channel == null ) // not yet waiting for alarm
            {
                channel = new IOChannel.unix_new( rtc_fd );
                watch = channel.add_watch( IOCondition.IN, onInputEvent );
            }
            this.wakeup_time_changed( seconds_since_epoch ); // DBUS SIGNAL
        }
        else
        {
            if ( watch > 0 )
            {
                Source.remove( watch );
            }
            channel = null;
            closeRtc();
        }
    }
}

} /* namespace */

static string sysfs_root;
static string sys_class_rtcs;
List<Kernel26.Rtc> instances;

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    // grab sysfs paths
    var config = FsoFramework.theConfig;
    sysfs_root = config.stringValue( "cornucopia", "sysfs_root", "/sys" );
    sys_class_rtcs = "%s/class/rtc".printf( sysfs_root );

    // scan sysfs path for rtcs
    var dir = Dir.open( sys_class_rtcs );
    var entry = dir.read_name();
    while ( entry != null )
    {
        var filename = Path.build_filename( sys_class_rtcs, entry );
        instances.append( new Kernel26.Rtc( subsystem, filename ) );
        entry = dir.read_name();
    }
    return "fsodevice.kernel26_rtc";
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    debug( "fsodevice.kernel26_rtc fso_register_function()" );
}

/**
 * This function gets called on plugin load time.
 * @return false, if the plugin operating conditions are present.
 * @note Some versions of glib contain a bug that leads to a SIGSEGV
 * in g_module_open, if you return true here.
 **/
/*public static bool g_module_check_init( void* m )
{
    var ok = FsoFramework.FileHandling.isPresent( Kernel26.SYS_CLASS_LEDS );
    return (!ok);
}
*/
