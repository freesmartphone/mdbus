include $(top_srcdir)/Makefile.decl

NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	dbus_service \
	\
	lowlevel_openmoko \
	\
	modem_singleline \
	modem_qualcomm_htc \
	$(NULL)

if WANT_MUX
SUBDIRS += modem_ti_calypso modem_cinterion_mc75
endif	

if WANT_PALM
SUBDIRS += modem_qualcomm_palm
endif
