/* libgps.vapi
 *
 * Copyright (C) 2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

[CCode (lower_case_cprefix = "gps_", cheader_filename = "gps.h")]
namespace Gps {

    /* delegates */
    [CCode (has_target = false)]
    public delegate void RawHookFunc( Device device, uint8[] data );

    /* enums and constants */
    [CCode (cname = "uint", has_type_id = false, cprefix = "WATCH_", cheader_filename = "gps.h")]
    public enum StreamingPolicy
    {
        ENABLE,
        JSON,
        NMEA,
        RARE,
        RAW,
        SCALED,
        NEWSTYLE,
        OLDSTYLE,
        DEVICE,
        DISABLE,
        SUBFRAMES
    }
    [CCode (cheader_filename = "gps.h")]
    public const uint POLL_NONBLOCK;
    [CCode (cheader_filename = "gps.h")]
    public const uint MAXTAGLEN;
    [CCode (cheader_filename = "gps.h")]
    public const uint MAXCHANNELS;
    [CCode (cheader_filename = "gps.h")]
    public const uint GPS_PRNMAX;
    [CCode (cheader_filename = "gps.h")]
    public const uint GPS_PATH_MAX;
    [CCode (cheader_filename = "gps.h")]
    public const uint GPS_BUFFER_MAX;
    [CCode (cheader_filename = "gps.h")]
    public const uint MAXUSERDEVS;

    [CCode (cname = "uint", has_type_id = false, cprefix = "", cheader_filename = "gps.h")]
    public enum ChangeMask
    {
        ONLINE_SET,
        TIME_SET,
        TIMERR_SET,
        LATLON_SET,
        ALTITUDE_SET,
        SPEED_SET,
        TRACK_SET,
        CLIMB_SET,
        STATUS_SET,
        MODE_SET,
        DOP_SET,
        VERSION_SET,
        HERR_SET,
        VERR_SET,
        ATTITUDE_SET,
        POLICY_SET,
        SATELLITE_SET,
        RAW_SET,
        USED_SET,
        SPEEDERR_SET,
        TRACKERR_SET,
        CLIMBERR_SET,
        DEVICE_SET,
        DEVICELIST_SET,
        DEVICEID_SET,
        ERROR_SET,
        RTCM2_SET,
        RTCM3_SET,
        AIS_SET,
        PACKET_SET,
        SUBFRAME_SET,
        AUXDATA_SET

        //[CCode (cname = "gps_maskdump", cheader_filename = "gps.h")]
        //public unowned string dump();
    }

    [CCode (cname = "int", has_type_id = false, cprefix = "SEEN_", cheader_filename = "gps.h")]
    public enum SeenFlags
    {
        GPS,
        RTCM2,
        RTCM3,
        AIS
    }

    [CCode (cname = "uint", has_type_id = false, cprefix = "STATUS_", cheader_filename = "gps.h")]
    public enum FixStatus
    {
        NO_FIX,
        FIX,
        DGPS_FIX,
    }

    [CCode (cname = "uint", has_type_id = false, cprefix = "", cheader_filename = "gps.h")]
    public enum FixMode
    {
        MODE_NOT_SEEN,
        MODE_NO_FIX,
        MODE_2D,
        MODE_3D
    }

    /* static functions */
    public static unowned string errstr( int errno );
    public void enable_debug( int fd, Posix.FILE file );

    /* fix */
    [CCode (cname = "struct gps_fix_t", destroy_function = "", cprefix = "gps_", cheader_filename = "gps.h")]
    public struct Fix
    {
        public double time;
        public FixMode mode;
        public double ept;
        public double latitude;
        public double epy;
        public double longitude;
        public double epx;
        public double altitude;
        public double epv;
        public double track;
        public double epd;
        public double speed;
        public double eps;
        public double climb;
        public double epc;

        public void clear_fix();
        public void merge_fix( ChangeMask mask, Fix otherFix );
    }

    /* dilution of precision */
    [CCode (cname = "struct dop_t", destroy_function = "", cprefix = "", cheader_filename = "gps.h")]
    public struct Dop
    {
        public double xdop;
        public double ydop;
        public double pdop;
        public double hdop;
        public double vdop;
        public double tdop;
        public double gdop;
    }

    /* device configuration */
    [CCode (cname = "struct devconfig_t", destroy_function = "", cprefix = "", cheader_filename = "gps.h")]
    public struct DeviceConfig
    {
        public unowned string path;
        public SeenFlags flags;
        public unowned string driver;
        public unowned string subtype;
        public double activated;
        uint baudrate;
        uint stopbits;
        char parity;
        double cycle;
        double mincycle;
        int driver_mode;
    }

    /* device */
    [CCode (cname = "struct gps_data_t", destroy_function = "gps_close", cprefix = "gps_", cheader_filename = "gps.h")]
    public struct Device
    {
        public uint @set;
        public double online;
        public Fix fix;
        public double separation;
        public FixStatus status;
        public int satellites_used;
        public int used[];
        public Dop dop;
        public double epe;
        public double skyview_time;
        public int satellites_visible;
        public int PRN[];
        public int elevation[];
        public int azimuth[];
        public double ss[];
        public DeviceConfig dev;
        public StreamingPolicy policy;

        [CCode (cname = "gps_open_r",instance_pos = -1)]
        public int open( string server = "localhost", string port = "2947" );

        public void close();

        [PrintfFormat]
        public size_t send( string format, ... );
        public size_t read();
        public bool waiting( int timeout );
        public int stream( StreamingPolicy flags, void* data = null );
        public void set_raw_hook( RawHookFunc func );
    }
}

#if 0

extern time_t mkgmtime(register struct tm *);
extern double timestamp(void);
extern double iso8601_to_unix(char *);
extern /*@observer@*/char *unix_to_iso8601(double t, /*@ out @*/char[], size_t len);
extern double gpstime_to_unix(int, double);
extern void unix_to_gpstime(double, /*@out@*/int *, /*@out@*/double *);
extern double earth_distance(double, double, double, double);
extern double earth_distance_and_bearings(double, double, double, double,
					  /*@null@*//*@out@*/double *,
					  /*@null@*//*@out@*/double *);
extern double wgs84_separation(double, double);

#endif

// vim:ts=4:sw=4:expandtab

