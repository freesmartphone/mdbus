include $(top_srcdir)/Makefile.decl
NULL =

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	alarm \
	\
	contextmanager \
	\
	provider_gps \
	provider_gps_nmea \
	\
	provider_location_cellidwifi \
	provider_location_dummy \
	provider_location_freegeoip \
	\
	source_dummy \
	source_gps \
	source_gpsddbus \
	source_gsm \
	source_ntp \
	\
	sync_time \
	$(NULL)

if WANT_LIBGPS
SUBDIRS += provider_location_gpsd
endif

