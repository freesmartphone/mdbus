include $(top_srcdir)/Makefile.decl

NULL =

AM_CFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(NULL)

progs_ldadd = \
	$(top_srcdir)/src/lib/libfsodevice.la \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--vapidir $(top_srcdir)/vapi \
	--pkg glib-2.0 \
	--pkg gee-1.0 \
	--pkg linux \
	--pkg fso-glib-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsodevice-2.0

if WANT_DEBUG
VALAC_ARGS += -g -D DEBUG
AM_CFLAGS += -ggdb -O0
endif

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
