include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	-I../fsoframework \
	$(GLIB_CFLAGS) \
	$(DBUS_CFLAGS) \
	$(NULL)

INCLUDES = \
	-I../fsoframework

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = $(GLIB_LIBS) $(DBUS_LIBS) ../fsoframework/libfsoframework.la

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
# smartkeyfile test
#
TEST_PROGS += testsmartkeyfile
testsmartkeyfile_VALASOURCES = testsmartkeyfile.vala
testsmartkeyfile_SOURCES = testsmartkeyfile.c
$(testsmartkeyfile_SOURCES): $(testsmartkeyfile_VALASOURCES)
	$(VALAC) $(VALAC_ARGS) $^
	touch $@
testsmartkeyfile_LDADD = $(progs_ldadd)
EXTRA_DIST += $(testsmartkeyfile_VALASOURCES)

#
# logger test
#
TEST_PROGS += testlogger
testlogger_VALASOURCES = testlogger.vala
testlogger_SOURCES = testlogger.c
$(testlogger_SOURCES): $(testlogger_VALASOURCES)
	$(VALAC) $(VALAC_ARGS) $^
	touch $@
testlogger_LDADD = $(progs_ldadd)
EXTRA_DIST += $(testlogger_VALASOURCES)

#
# plugin for the plugin test
#
modlibexecdir = $(libdir)/cornucopia/modules/tests
modlibexec_LTLIBRARIES = plugin.la
plugin_la_SOURCES = plugin.c
plugin_la_VALASOURCES = plugin.vala
$(plugin_la_SOURCES): $(plugin_la_VALASOURCES)
	$(VALAC) $(VALAC_ARGS) $^
	touch $@
plugin_la_LIBADD = $(progs_ldadd)
plugin_la_LDFLAGS = -no-undefined -module -avoid-version
plugin_la_LIBTOOLFLAGS = --tag=disable-static

#
# plugin a for the subsystem test
#
modalibexecdir = $(libdir)/cornucopia/modules/tests
modalibexec_LTLIBRARIES = plugina.la
plugina_la_SOURCES = plugina.c
plugina_la_VALASOURCES = plugina.vala
$(plugina_la_SOURCES): $(plugina_la_VALASOURCES)
	$(VALAC) $(VALAC_ARGS) $^
	touch $@
plugina_la_LIBADD = $(progs_ldadd)
plugina_la_LDFLAGS = -no-undefined -module -avoid-version
plugina_la_LIBTOOLFLAGS = --tag=disable-static

#
# plugin b for the subsystem test
#
modblibexecdir = $(libdir)/cornucopia/modules/tests
modblibexec_LTLIBRARIES = pluginb.la
pluginb_la_SOURCES = pluginb.c
pluginb_la_VALASOURCES = pluginb.vala
$(pluginb_la_SOURCES): $(pluginb_la_VALASOURCES)
	$(VALAC) $(VALAC_ARGS) $^
	touch $@
pluginb_la_LIBADD = $(progs_ldadd)
pluginb_la_LDFLAGS = -no-undefined -module -avoid-version
pluginb_la_LIBTOOLFLAGS = --tag=disable-static

#
# plugin c for the subsystem test
#
modclibexecdir = $(libdir)/cornucopia/modules/tests
modclibexec_LTLIBRARIES = pluginc.la
pluginc_la_SOURCES = pluginc.c
pluginc_la_VALASOURCES = pluginc.vala
$(pluginc_la_SOURCES): $(pluginc_la_VALASOURCES)
	$(VALAC) $(VALAC_ARGS) $^
	touch $@
pluginc_la_LIBADD = $(progs_ldadd)
pluginc_la_LDFLAGS = -no-undefined -module -avoid-version
pluginc_la_LIBTOOLFLAGS = --tag=disable-static

#
# plugin test
#
TEST_PROGS += testplugin
testplugin_VALASOURCES = testplugin.vala
testplugin_SOURCES = testplugin.c
$(testplugin_SOURCES): $(testplugin_VALASOURCES)
	$(VALAC) $(VALAC_ARGS) $^
	touch $@
testplugin_LDADD = $(progs_ldadd)
EXTRA_DIST += $(testplugin_VALASOURCES)

#
# subsystem test
#
TEST_PROGS += testsubsystem
testsubsystem_VALASOURCES = testsubsystem.vala
testsubsystem_SOURCES = testsubsystem.c
$(testsubsystem_SOURCES): $(testsubsystem_VALASOURCES)
	$(VALAC) $(VALAC_ARGS) $^
	touch $@
testsubsystem_LDADD = $(progs_ldadd)
EXTRA_DIST += $(testsubsystem_VALASOURCES)

#
# utilities test
#
TEST_PROGS += testutilities
testutilities_VALASOURCES = testutilities.vala
testutilities_SOURCES = testutilities.c
$(testutilities_SOURCES): $(testutilities_VALASOURCES)
	$(VALAC) $(VALAC_ARGS) $^
	touch $@
testutilities_LDADD = $(progs_ldadd)
EXTRA_DIST += $(testutilities_VALASOURCES)

#
# object test
#
TEST_PROGS += testobject
testobject_VALASOURCES = testobject.vala
testobject_SOURCES = testobject.c
$(testobject_SOURCES): $(testobject_VALASOURCES)
	$(VALAC) $(VALAC_ARGS) $^
	touch $@
testobject_LDADD = $(progs_ldadd)
EXTRA_DIST += $(testobject_VALASOURCES)

#
# asyncworker test
#
TEST_PROGS += testasyncworker
testasyncworker_VALASOURCES = testasyncworker.vala
testasyncworker_SOURCES = testasyncworker.c
$(testasyncworker_SOURCES): $(testasyncworker_VALASOURCES)
	$(VALAC) $(VALAC_ARGS) $^
	touch $@
testasyncworker_LDADD = $(progs_ldadd)
EXTRA_DIST += $(testasyncworker_VALASOURCES)

#
# kobjectnotifier test
#
TEST_PROGS += testkobjectnotifier
testkobjectnotifier_VALASOURCES = testkobjectnotifier.vala
testkobjectnotifier_SOURCES = testkobjectnotifier.c
$(testkobjectnotifier_SOURCES): $(testkobjectnotifier_VALASOURCES)
	$(VALAC) $(VALAC_ARGS) $^
	touch $@
testkobjectnotifier_LDADD = $(progs_ldadd)
EXTRA_DIST += $(testkobjectnotifier_VALASOURCES)

CLEANFILES = \
    $(TEST_PROGS) \
    *.? \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  *.la \
  *.lo \
  $(NULL)
