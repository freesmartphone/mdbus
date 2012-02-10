include $(top_srcdir)/Makefile.decl

NULL =

AM_CFLAGS = \
	-I$(top_srcdir) \
	-I../fsoframework \
	$(GLIB_CFLAGS) \
	$(DBUS_CFLAGS) \
	$(FSOBASICS_CFLAGS) \
	$(NULL)

INCLUDES = \
	-I../fsoframework

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(GLIB_LIBS) \
	$(DBUS_LIBS) \
	$(FSOBASICS_LIBS) \
	../fsoframework/libfsoframework.la

VALAC_ARGS = \
	-C \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/fsoframework \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg dbus-glib-1 \
	--pkg fsoframework-2.0

#
# dbus test
#
# TEST_PROGS += testdbus
# testdbus_VALASOURCES = testdbus.vala
# testdbus_SOURCES = testdbus.c
# $(testdbus_SOURCES): $(testdbus_VALASOURCES)
#	$(VALAC) $(VALAC_ARGS) $^
#	touch $@
# testdbus_LDADD = $(progs_ldadd)
# EXTRA_DIST += $(testdbus_VALASOURCES)

CLEANFILES = \
    $(TEST_PROGS) \
    *.? \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  *.la \
  *.lo \
  $(NULL)
