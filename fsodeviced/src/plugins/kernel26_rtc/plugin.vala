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
public const int IOCTL_RTC_RD_TIME = 0x80247009;
public const int IOCTL_RTC_SET_TIME = 0x4024700a;
public const int IOCTL_RTC_WKALM_RD = 0x80287010;
public const int IOCTL_RTC_WKALM_SET = 0x4028700f;

/**
 * Implementation of org.freesmartphone.Device.RTC for the Kernel26 Real-Time-Clock interface
 **/
class Rtc : FsoFramework.Device.RTC, FsoFramework.AbstractObject
{
    FsoFramework.Subsystem subsystem;

    private string sysfsnode;
    private string devnode;
    private int rtc_fd;
    private static uint counter;

    public Rtc( FsoFramework.Subsystem subsystem, string sysfsnode )
    {
        this.subsystem = subsystem;
        this.sysfsnode = sysfsnode;
        this.devnode = sysfsnode.replace( "/sys/class/rtc/", "/dev/" );

        rtc_fd = Posix.open( this.devnode, Posix.O_RDONLY );
        if ( rtc_fd == -1 )
            logger.warning( "Can't open %s (%s). Full RTC control not available.".printf( devnode, Posix.strerror( Posix.errno ) ) );

        subsystem.registerServiceName( FsoFramework.Device.ServiceDBusName );
        subsystem.registerServiceObject( FsoFramework.Device.ServiceDBusName,
                                         "%s/%u".printf( FsoFramework.Device.RtcServicePath, counter++ ),
                                         this );

        logger.info( "created new Rtc object." );
    }

    public override string repr()
    {
        return "<FsoFramework.Device.Rtc @ %s : %s>".printf( sysfsnode, devnode );
    }

    //
    // FsoFramework.Device.RTC
    //
    public string GetName() throws DBus.Error
    {
        return Path.get_basename( sysfsnode );
    }

    public int GetCurrentTime() throws FsoFramework.OrgFreesmartphone, DBus.Error
    {
        GLib.Time time = {};
        var res = Posix.ioctl( rtc_fd, Linux26.Rtc.RTC_RD_TIME, &time );
        if ( res == -1 )
            throw new FsoFramework.OrgFreesmartphone.SystemError( Posix.strerror( Posix.errno ) );

        return (int) time.mktime();
    }

    public void SetCurrentTime( int seconds_since_epoch ) throws FsoFramework.OrgFreesmartphone, DBus.Error
    {
        var time = GLib.Time.gm( (time_t) seconds_since_epoch ); // VALABUG: cast is necessary here, otherwise things go havoc
        var res = Posix.ioctl( rtc_fd, Linux26.Rtc.RTC_SET_TIME, &time );
        if ( res == -1 )
            throw new FsoFramework.OrgFreesmartphone.SystemError( Posix.strerror( Posix.errno ) );
    }

    public int GetWakeupTime() throws FsoFramework.OrgFreesmartphone, DBus.Error
    {
        Linux26.Rtc.WakeAlarm alarm = {};
        var res = Posix.ioctl( rtc_fd, Linux26.Rtc.RTC_WKALM_RD, &alarm );
        if ( res == -1 )
            throw new FsoFramework.OrgFreesmartphone.SystemError( Posix.strerror( Posix.errno ) );

        GLib.Time time = {};
        Memory.copy( &time, &alarm.time, sizeof( GLib.Time ) );
        return ( alarm.enabled == 1 ) ? (int) time.mktime() : 0;
    }

    public void SetWakeupTime( int seconds_since_epoch ) throws FsoFramework.OrgFreesmartphone, DBus.Error
    {
        Linux26.Rtc.WakeAlarm alarm = {};
        var time = GLib.Time.gm( (time_t) seconds_since_epoch );

        // VALABUG 1: var time and var time in two different clauses
        // VALABUG 2: Memory.copy goes havok!

        alarm.time.second = time.second;
        alarm.time.minute = time.minute;
        alarm.time.hour = time.hour;
        alarm.time.day = time.day;
        alarm.time.month = time.month;
        alarm.time.year = time.year;
        alarm.time.weekday = time.weekday;
        alarm.time.day_of_year = time.day_of_year;
        alarm.time.isdst = time.isdst;

        alarm.enabled = seconds_since_epoch > 0 ? 1 : 0;

        var res = Posix.ioctl( rtc_fd, Linux26.Rtc.RTC_WKALM_SET, &alarm );
        if ( res == -1 )
            throw new FsoFramework.OrgFreesmartphone.SystemError( Posix.strerror( Posix.errno ) );
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
    var config = FsoFramework.theMasterKeyFile();
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
    debug( "kernel26_rtc fso_register_function()" );
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