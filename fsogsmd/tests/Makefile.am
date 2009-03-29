include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	$(DEPS_CFLAGS) \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = $(DEPS_LIBS) ../fsogsmd/lib/libfsogsmd.la

# TEST_PROGS += testsmartkeyfile
# testsmartkeyfile_VALASOURCES = testsmartkeyfile.vala
# testsmartkeyfile_SOURCES = testsmartkeyfile.c testsmartkeyfile.h
# $(testsmartkeyfile_SOURCES): $(testsmartkeyfile_VALASOURCES)
# 	$(VALAC) -C --basedir $(top_srcdir) --vapidir $(top_srcdir)/fsoframework --pkg glib-2.0 --pkg gio-2.0 --pkg fsoframework-2.0 $^
# 	touch $@
# testsmartkeyfile_LDADD = $(progs_ldadd)
# EXTRA_DIST += $(testsmartkeyfile_VALASOURCES)
# 
# TEST_PROGS += testlogger
# testlogger_VALASOURCES = testlogger.vala
# testlogger_SOURCES = testlogger.c testlogger.h
# $(testlogger_SOURCES): $(testlogger_VALASOURCES)
# 	$(VALAC) -C --basedir $(top_srcdir) --vapidir $(top_srcdir)/fsoframework --pkg glib-2.0 --pkg gio-2.0 --pkg fsoframework-2.0 $^
# 	touch $@
# testlogger_LDADD = $(progs_ldadd)
# EXTRA_DIST += $(testlogger_VALASOURCES)

# TEST_PROGS += testarraylist
# testarraylist_VALASOURCES = testarraylist.vala
# testarraylist_SOURCES = testarraylist.c testarraylist.h
# $(testarraylist_SOURCES): $(testarraylist_VALASOURCES)
# 	$(VALAC) -C --basedir $(top_srcdir) --vapidir $(top_srcdir)/fsoframework --pkg fsoframework-2.0 $^
# 	touch $@
# testarraylist_LDADD = $(progs_ldadd)
# EXTRA_DIST += $(testarraylist_VALASOURCES)
#
# TEST_PROGS += testhashmap
# testhashmap_VALASOURCES = testhashmap.vala
# testhashmap_SOURCES = testhashmap.c testhashmap.h
# $(testhashmap_SOURCES): $(testhashmap_VALASOURCES)
# 	$(VALAC) -C --basedir $(top_srcdir) --vapidir $(top_srcdir)/fsoframework --pkg fsoframework-2.0 $^
# 	touch $@
# testhashmap_LDADD = $(progs_ldadd)
# EXTRA_DIST += $(testhashmap_VALASOURCES)
#
# TEST_PROGS += testhashset
# testhashset_VALASOURCES = testhashset.vala
# testhashset_SOURCES = testhashset.c testhashset.h
# $(testhashset_SOURCES): $(testhashset_VALASOURCES)
# 	$(VALAC) -C --basedir $(top_srcdir) --vapidir $(top_srcdir)/fsoframework --pkg fsoframework-2.0 $^
# 	touch $@
# testhashset_LDADD = $(progs_ldadd)
# EXTRA_DIST += $(testhashset_VALASOURCES)
#

CLEANFILES = \
    $(TEST_PROGS) \
    *.? \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
