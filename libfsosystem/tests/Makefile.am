include $(top_srcdir)/Makefile.decl

NULL =

AM_CFLAGS = \
	-I../fsosystem \
	$(GLIB_CFLAGS) \
	$(DBUS_CFLAGS) \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(GLIB_LIBS) \
	$(DBUS_LIBS) \
	../fsosystem/libfsosystem.la \
	$(NULL)

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/fsosystem \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fsosystem-2.0

#
# modules test
#
TEST_PROGS += testmodules
testmodules_VALASOURCES = testmodules.vala
testmodules_SOURCES = testmodules.c
$(testmodules_SOURCES): $(testmodules_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
testmodules_LDADD = $(progs_ldadd)
EXTRA_DIST += $(testmodules_VALASOURCES)

#
# network test
#
TEST_PROGS += testnetwork
testnetwork_VALASOURCES = testnetwork.vala
testnetwork_SOURCES = testnetwork.c
$(testnetwork_SOURCES): $(testnetwork_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
testnetwork_LDADD = $(progs_ldadd)
EXTRA_DIST += $(testnetwork_VALASOURCES)

#
# path test
#
TEST_PROGS += testpath
testpath_VALASOURCES = testpath.vala
testpath_SOURCES = testpath.c
$(testpath_SOURCES): $(testpath_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
testpath_LDADD = $(progs_ldadd)
EXTRA_DIST += $(testpath_VALASOURCES)


CLEANFILES = \
    $(TEST_PROGS) \
    *.? \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  *.la \
  *.lo \
  $(NULL)
