include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	$(GLIB_CFLAGS) \
	$(DBUS_CFLAGS) \
	-I../fsoresource \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = $(GLIB_LIBS) $(DBUS_LIBS) ../fsoresource/libfsoresource.la

VALAC_ARGS = \
	-C \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/fsoresource \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg fsoresource-2.0

#
# resource test
#
TEST_PROGS += testresource
testresource_VALASOURCES = testresource.vala
testresource_SOURCES = testresource.c
$(testresource_SOURCES): $(testresource_VALASOURCES)
	$(VALAC) $(VALAC_ARGS) $^
	touch $@
testresource_LDADD = $(progs_ldadd)
EXTRA_DIST += $(testresource_VALASOURCES)

CLEANFILES = \
    $(TEST_PROGS) \
    *.? \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  *.la \
  *.lo \
  $(NULL)
