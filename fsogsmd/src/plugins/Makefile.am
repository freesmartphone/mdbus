
include $(top_srcdir)/Makefile.decl

NULL =

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	dbus_service \
	\
	lowlevel_openmoko \
	lowlevel_motorola_ezx \
	lowlevel_nokia900 \
	\
	modem_dummy \
	modem_singleline \
	modem_qualcomm_htc \
	modem_freescale_neptune \
	modem_nokia_isi \
	\
	pdp_qmi \
	$(NULL)

if WANT_PPP
SUBDIRS += pdp_ppp
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
SUBDIRS += modem_qualcomm_palm
endif
