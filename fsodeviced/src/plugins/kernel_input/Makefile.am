NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	$(FSO_CFLAGS) \
	$(DBUS_CFLAGS) \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = $(FSO_LIBS) $(DBUS_LIBS) $(top_srcdir)/src/lib/libfsodevice.la

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/fsoframework \
	--pkg glib-2.0 \
	--pkg dbus-glib-1 \
	--pkg posix \
	--pkg linux26 \
	--pkg fsoframework-2.0

#
# plugin
#
modlibexecdir = $(libdir)/cornucopia/modules/fsodevice
modlibexec_LTLIBRARIES = kernel_input.la
kernel_input_la_SOURCES = plugin.c
kernel_input_la_VALASOURCES = plugin.vala
$(kernel_input_la_SOURCES): $(kernel_input_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
kernel_input_la_LIBADD = $(progs_ldadd)
kernel_input_la_LDFLAGS = -no-undefined -module -avoid-version
kernel_input_la_LIBTOOLFLAGS = --tag=disable-static

CLEANFILES = \
    *.c \
    *.h \
    *.la \
    *.lo \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
