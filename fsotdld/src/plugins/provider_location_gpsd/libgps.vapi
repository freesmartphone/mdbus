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

    /* flags */
    [CCode (cname = "uint", cprefix = "WATCH_", cheader_filename = "gps.h")]
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

    /* static functions */
    public static unowned string errstr(int errno);

    /* device */
    [CCode (cname = "struct gps_data_t", destroy_function = "gps_close", cprefix = "gps_", cheader_filename = "gps.h")]
    public struct Device {

        [CCode (cname = "gps_open", instance_pos = -1)]
        public int open( string server = "localhost", string port = "2947" );

        [PrintfFormat]
        public size_t send( string format, ... );
        public size_t read();
        public bool waiting();
        public int stream( StreamingPolicy flags, void* data = null );
        //public void set_raw_hook( struct gps_data_t *, void (*)(struct gps_data_t *, char *, size_t) );
    }
}


#if 0


extern void gps_clear_fix(/*@ out @*/struct gps_fix_t *);
extern void gps_merge_fix(/*@ out @*/struct gps_fix_t *,
			  gps_mask_t,
			  /*@ in @*/struct gps_fix_t *);
extern void gps_enable_debug(int, FILE *);
extern /*@observer@*/const char *gps_maskdump(gps_mask_t);

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

