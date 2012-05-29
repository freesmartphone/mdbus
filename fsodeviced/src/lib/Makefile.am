include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-DG_LOG_DOMAIN=\"fsodevice.lib\" \
	$(NULL)
AM_VALAFLAGS =

modlibexecdir = $(libdir)/cornucopia/modules/fsodevice
modlibexec_LTLIBRARIES = libfsodevice.la

libfsodevice_la_SOURCES = \
	accelerometer.vala \
	alsa.vala \
	audioplayer.vala \
	audiorouter.vala \
	input.vala \
	powercontrol.vala \
	resource.vala \
	$(NULL)
libfsodevice_la_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/vapi \
	--pkg linux \
	--pkg posix \
	--pkg alsa \
	--pkg glib-2.0 \
	--pkg gee-1.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoresource-2.0 \
	--pkg fsoframework-2.0 \
	--header fsodevice.h \
	--library fsodevice-2.0
	$(NULL)
libfsodevice_la_CFLAGS = \
	-I$(top_srcdir) \
	$(FSO_CFLAGS) \
	$(ALSA_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(NULL)
libfsodevice_la_LIBADD = \
	$(FSO_LIBS) \
	$(ALSA_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)
libfsodevice_la_LDFLAGS = -no-undefined -avoid-version

EXTRA_DIST += \
	fsodevice-2.0.deps \
	$(NULL)

CLEANFILES =
MAINTAINERCLEANFILES = \
	fsogsmd.h \
	fsodevice-2.0.vapi \
	Makefile.in \
	$(NULL)
