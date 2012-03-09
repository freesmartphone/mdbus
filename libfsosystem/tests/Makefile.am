include $(top_srcdir)/Makefile.decl

NULL =

AM_CFLAGS = \
	-I$(top_srcdir)/fsosystem \
	$(GLIB_CFLAGS) \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(GLIB_LIBS) \
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
