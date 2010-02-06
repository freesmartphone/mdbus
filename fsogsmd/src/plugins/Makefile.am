include $(top_srcdir)/Makefile.decl

NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	dbus_service \
	\
	lowlevel_openmoko \
	\
	modem_cinterion_mc75 \
	modem_singleline \
	modem_ti_calypso \
	modem_qualcomm_htc \
	$(NULL)

if WANT_PALM
SUBDIRS += modem_qualcomm_palm
endif
