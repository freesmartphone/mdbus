include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	$(GLIB_CFLAGS) \
	-I$(top_srcdir)/fsosystem \
	-include $(CONFIG_HEADER)
	$(NULL)

LDADD = \
	$(top_builddir)/fsosystem/libfsosystem.la \
	$(GLIB_LIBS) \
	$(NULL)

AM_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/fsosystem \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fsosystem-2.0
	$(NULL)

noinst_PROGRAMS = \
	testpath \
	$(NULL)

TEST_PROGS += $(noinst_PROGRAMS)

testpath_SOURCES = \
	testpath.vala \
	$(NULL)

CLEANFILES = \
	$(TEST_PROGS) \
	$(NULL)

MAINTAINERCLEANFILES = \
	$(addsuffix .c,$(noinst_PROGRAMS)) \
	testpath_vala.stamp \
	$(NULL)

EXTRA_DIST += \
	$(MAINTAINERCLEANFILES) \
	$(NULL)
