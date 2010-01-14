include $(top_srcdir)/Makefile.decl

NULL =

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	accelerometer \
	accelerometer_lis302 \
	\
	audio \
	router_alsa \
	router_qdsp5 \
	player_alsa \
	\
	kernel26_display \
	kernel26_leds \
	kernel26_powersupply \
	kernel26_rtc \
	\
	kernel_idle \
	kernel_info \
	kernel_input \
	\
	openmoko_powercontrol \
	thinkpad_powercontrol \
	\
	$(NULL)

if WANT_CANBERRA
SUBDIRS += player_canberra
endif

if WANT_GSTREAMER
SUBDIRS += player_gstreamer
endif

if WANT_RFKILL
SUBDIRS += kernel26_rfkill
endif
