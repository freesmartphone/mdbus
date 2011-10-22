
include $(top_srcdir)/Makefile.decl

NULL =

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	dbus_service \
	\
	lowlevel_openmoko \
	lowlevel_motorola_ezx \
	\
	modem_dummy \
	modem_singleline \
	modem_qualcomm_htc \
	modem_option_gtm601 \
	modem_freescale_neptune \
	\
	pdp_qmi \
	$(NULL)

if WANT_PPP
SUBDIRS += pdp_ppp pdp_ppp_internal
if WANT_MUX
SUBDIRS += pdp_ppp_mux
endif
endif

if WANT_MUX
SUBDIRS += \
	modem_ti_calypso \
	modem_cinterion_mc75
endif

if WANT_PALM
SUBDIRS += \
	modem_qualcomm_palm \
	lowlevel_palmpre
endif

if WANT_ISI
SUBDIRS += \
	modem_nokia_isi \
	pdp_nokia_isi
endif

if WANT_SAMSUNG
SUBDIRS += \
	lowlevel_samsung_crespo \
	modem_samsung
endif
