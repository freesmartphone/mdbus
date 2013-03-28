include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-DG_LOG_DOMAIN=\"fsodevice.vibrator_forcefeedback\" \
	$(NULL)
AM_VALAFLAGS =

modlibexecdir = $(libdir)/cornucopia/modules/fsodevice
modlibexec_LTLIBRARIES = vibrator_forcefeedback.la
vibrator_forcefeedback_la_SOURCES = plugin.vala vibration.c
vibrator_forcefeedback_la_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/fsoframework\
	--pkg glib-2.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	$(DEBUG_VALAFLAGS) \
	$(NULL)
vibrator_forcefeedback_la_CFLAGS = \
	-I$(top_srcdir) \
	$(FSO_CFLAGS) \
	$(DEBUG_CFLAGS) \
	$(NULL)
vibrator_forcefeedback_la_LIBADD = \
	$(FSO_LIBS) \
	$(top_builddir)/src/lib/libfsodevice.la \
	$(NULL)
vibrator_forcefeedback_la_LDFLAGS = -no-undefined -module -avoid-version

CLEANFILES = 
MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
