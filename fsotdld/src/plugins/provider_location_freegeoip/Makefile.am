include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	-DG_LOG_DOMAIN=\"fsotdld.provider_location_freegeoip\" \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(GEE_LIBS) \
	$(top_builddir)/src/lib/libfsotdl.la

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsotransport-2.0 \
	--pkg fsoresource-2.0 \
	--pkg fsotdl-2.0

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsotdl
modlibexec_LTLIBRARIES = provider_location_freegeoip.la
provider_location_freegeoip_la_SOURCES = plugin.c
provider_location_freegeoip_la_VALASOURCES = plugin.vala
$(provider_location_freegeoip_la_SOURCES): $(provider_location_freegeoip_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
provider_location_freegeoip_la_LIBADD = $(progs_ldadd)
provider_location_freegeoip_la_LDFLAGS = -no-undefined -module -avoid-version
provider_location_freegeoip_la_LIBTOOLFLAGS = --tag=disable-static

EXTRA_DIST += \
	$(provider_location_freegeoip_la_VALASOURCES) \
	$(provider_location_freegeoip_la_SOURCES) \
	$(NULL)

CLEANFILES = \
    *.c \
    *.h \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
