include $(top_srcdir)/Makefile.decl

NULL =

AM_CFLAGS = \
	-I$(top_srcdir)/src/lib \
	-I$(top_srcdir)/src/3rdparty \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	$(FSO_CFLAGS) \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(GLIB_LIBS) \
	$(GEE_LIBS) \
	$(FSO_LIBS) \
	../src/lib/libfsotdl.la

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsotdl-2.0

TEST_PROGS += testsourcentp
testsourcentp_VALASOURCES = testsourcentp.vala ../src/plugins/source_ntp/plugin.vala
testsourcentp_SOURCES = testsourcentp.c ../src/plugins/source_ntp/plugin.c
$(testsourcentp_SOURCES): $(testsourcentp_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@
testsourcentp_LDADD = $(progs_ldadd)
EXTRA_DIST += $(testsourcentp_VALASOURCES) $(testsourcentp_SOURCES)


CLEANFILES = \
    $(TEST_PROGS) \
    *.? \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
