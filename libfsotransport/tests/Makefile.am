include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	$(GLIB_CFLAGS) \
	$(DBUS_CFLAGS) \
	-I../fsotransport \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = $(GLIB_LIBS) $(DBUS_LIBS) ../fsotransport/libfsotransport.la

VALAC_ARGS = \
	-C \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/fsotransport \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg fsotransport-2.0

#
# transport test
#
TEST_PROGS += testtransport
testtransport_VALASOURCES = testtransport.vala
testtransport_SOURCES = testtransport.c
$(testtransport_SOURCES): $(testtransport_VALASOURCES)
	$(VALAC) $(VALAC_ARGS) $^
	touch $@
testtransport_LDADD = $(progs_ldadd)
EXTRA_DIST += $(testtransport_VALASOURCES)

CLEANFILES = \
    $(TEST_PROGS) \
    *.? \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  *.la \
  *.lo \
  $(NULL)
