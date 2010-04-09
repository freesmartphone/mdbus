include $(top_srcdir)/Makefile.decl

NULL =

AM_CFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(GLIB_CFLAGS) \
	$(FSO_CFLAGS) \
	$(NULL)

VALAC_ARGS = \
	-C \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg fsodevice-2.0

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(GLIB_LIBS) \
	$(FSO_LIBS) \
	../src/lib/libfsodevice.la

#
# soundsystem test
#
TEST_PROGS += testsoundsystem
testsoundsystem_VALASOURCES = testsoundsystem.vala
testsoundsystem_SOURCES = testsoundsystem.c
$(testsoundsystem_SOURCES): $(testsoundsystem_VALASOURCES)
	$(VALAC) $(VALAC_ARGS) $^
	touch $@
testsoundsystem_LDADD = $(progs_ldadd)
EXTRA_DIST += $(testsoundsystem_VALASOURCES)

CLEANFILES = \
    $(TEST_PROGS) \
    *.? \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
