include $(top_srcdir)/Makefile.decl

NULL =

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	ambientlight_palmpre \
	\
	accelerometer \
	accelerometer_kxsd9 \
	accelerometer_lis302 \
	\
	audio \
	router_alsa \
	router_qdsp5 \
    router_palmpre \
	player_alsa \
	\
	backlight_omappanel \
	\
	kernel26_display \
	kernel26_firmwareloader \
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
	vibrator_ledclass \
	vibrator_omapvibe \
	vibrator_timedoutputclass \
    \
    palmpre_powersupply \
    proximity_palmpre \
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

if WANT_HTCDREAM_POWERCONTROL
SUBDIRS += htcdream_powercontrol

