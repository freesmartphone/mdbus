include $(top_srcdir)/Makefile.decl
NULL =

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	accelerometer \
	accelerometer_kxsd9 \
	accelerometer_lis302 \
	accelerometer_bma180 \
	\
	audio \
	router_alsa \
	player_alsa \
	\
	backlight_omappanel \
	\
	kernel26_cpufreq \
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
	powercontrol_ifconfig \
	\
	vibrator_ledclass \
	vibrator_omapvibe \
	vibrator_timedoutputclass \
	vibrator_forcefeedback \
	\
	gta04_quirks \
	herring_quirks \
	n900_quirks \
	\
	gpio_input \
	dummy_input \
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

MAINTAINERCLEANFILES = \
	Makefile.in \
	$(NULL)
