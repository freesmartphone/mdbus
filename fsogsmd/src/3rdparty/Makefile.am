include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	$(GLIB_CFLAGS) \
	$(NULL)

lib_LTLIBRARIES = \
	libfsogsm3rdparty.la
	$(NULL)

libfsogsm3rdparty_la_SOURCES = \
	conversions.c \
	$(NULL)

libfsogsm3rdparty_la_LDFLAGS = \
	-static \
	$(NULL)

libfsogsm3rdparty_la_LIBADD = \
	$(GLIB_LIBS) \
	$(NULL)

vapidir = $(datadir)/vala/vapi

dist_vapi_DATA = \
	fsogsm3rdparty.vapi \
	fsogsm3rdparty.deps \
	$(NULL)

MAINTAINERCLEANFILES = \
	Makefile.in

