NULL =

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	accelerometer \
	accelerometer_lis302 \
	\
	alsa_audio \
	player_alsa \
	\
	kernel26_display \
	kernel26_leds \
	kernel26_powersupply \
	kernel26_rfkill \
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

if BUILD_CANBERRA
SUBDIRS += player_canberra
endif
