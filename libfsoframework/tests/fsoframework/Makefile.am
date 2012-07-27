include $(top_srcdir)/Makefile.decl

NULL =

AM_CFLAGS = \
	-I$(top_srcdir) \
	-I$(top_srcdir)/fsobasics \
	-I$(top_srcdir)/fsoframework \
	$(GLIB_CFLAGS) \
	$(DBUS_CFLAGS) \
	$(FSOBASICS_CFLAGS) \
	$(LIBNL_CFLAGS) \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

LDADD = \
	$(GLIB_LIBS) \
	$(DBUS_LIBS) \
	$(top_builddir)/fsobasics/libfsobasics.la \
	$(top_builddir)/fsoframework/libfsoframework.la \
	$(NULL)

AM_VALAFLAGS = \
	-C \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/fsobasics \
	--vapidir $(top_srcdir)/fsoframework \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg fsoframework-2.0
	$(NULL)

modlibexecdir = $(libdir)/cornucopia/modules/tests
modlibexec_LTLIBRARIES = \
	plugin.la \
	plugina.la \
	pluginb.la \
	pluginc.la \
	$(NULL)

#
# plugin for the plugin test
#
plugin_la_SOURCES = plugin.vala
plugin_la_LDFLAGS = -no-undefined -module -avoid-version

#
# plugin a for the subsystem test
#
plugina_la_SOURCES = plugina.c
plugina_la_SOURCES = plugina.vala
plugina_la_LDFLAGS = -no-undefined -module -avoid-version

#
# plugin b for the subsystem test
#
pluginb_la_SOURCES = pluginb.vala
pluginb_la_LDFLAGS = -no-undefined -module -avoid-version

#
# plugin c for the subsystem test
#
pluginc_la_SOURCES = pluginc.vala
pluginc_la_LDFLAGS = -no-undefined -module -avoid-version

TEST_PROGS += \
	testdbus \
	testplugin \
	testobject \
	$(NULL)

# testsubsystem

testdbus_SOURCES = testdbus.vala
testplugin_SOURCES = testplugin.vala
testsubsystem_SOURCES = testsubsystem.vala
testobject_SOURCES = testobject.vala

CLEANFILES = \
	$(TEST_PROGS) \
	$(NULL)
MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)

EXTRA_DIST += \
	$(MAINTAINERCLEANFILES) \
	lt-testsubsystem.conf \
	$(NULL)
