include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	-DG_LOG_DOMAIN=\"fsodevice.kernel26_cpufreq\" \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(top_builddir)/src/lib/libfsodevice.la

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/fsoframework \
	--pkg linux \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsodevice
modlibexec_LTLIBRARIES = kernel26_cpufreq.la
kernel26_cpufreq_la_SOURCES = plugin.c
kernel26_cpufreq_la_VALASOURCES = plugin.vala
$(kernel26_cpufreq_la_SOURCES): $(kernel26_cpufreq_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
kernel26_cpufreq_la_LIBADD = $(progs_ldadd)
kernel26_cpufreq_la_LDFLAGS = -no-undefined -module -avoid-version
kernel26_cpufreq_la_LIBTOOLFLAGS = --tag=disable-static

EXTRA_DIST += \
	$(kernel26_cpufreq_la_VALASOURCES) \
	$(kernel26_cpufreq_la_SOURCES) \
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
