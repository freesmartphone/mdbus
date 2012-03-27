include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	$(FSO_CFLAGS) \
	-DG_LOG_DOMAIN=\"fsodevice.kernel_info\" \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = $(FSO_LIBS) $(DBUS_LIBS) $(top_builddir)/src/lib/libfsodevice.la

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/fsoframework \
	--pkg glib-2.0 \
	--pkg linux \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsodevice
modlibexec_LTLIBRARIES = kernel_info.la
kernel_info_la_SOURCES = plugin.c
kernel_info_la_VALASOURCES = plugin.vala
$(kernel_info_la_SOURCES): $(kernel_info_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
kernel_info_la_LIBADD = $(progs_ldadd)
kernel_info_la_LDFLAGS = -no-undefined -module -avoid-version
kernel_info_la_LIBTOOLFLAGS = --tag=disable-static

EXTRA_DIST += \
	$(kernel_info_la_VALASOURCES) \
	$(kernel_info_la_SOURCES) \
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
