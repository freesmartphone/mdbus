include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	$(DEPS_CFLAGS) \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = $(DEPS_LIBS) ../fsodeviced/lib/libfsodeviced.la

EXTRA_DIST += $(NULL)

# TEST_PROGS += testsmartkeyfile
# testsmartkeyfile_VALASOURCES = testsmartkeyfile.vala
# testsmartkeyfile_SOURCES = testsmartkeyfile.c
# $(testsmartkeyfile_SOURCES): $(testsmartkeyfile_VALASOURCES)
# 	$(VALAC) -C --basedir $(top_srcdir) --vapidir $(top_srcdir)/fsoframework --pkg glib-2.0 --pkg gio-2.0 --pkg fsoframework-2.0 $^
# 	touch $@
# testsmartkeyfile_LDADD = $(progs_ldadd)
# EXTRA_DIST += $(testsmartkeyfile_VALASOURCES)
# 

CLEANFILES = \
    $(TEST_PROGS) \
    *.? \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
