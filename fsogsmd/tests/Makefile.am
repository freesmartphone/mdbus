include $(top_srcdir)/Makefile.decl

NULL =

SUBDIRS = integration

AM_CFLAGS = \
	-I$(top_srcdir)/src/lib \
	-I$(top_srcdir)/src/3rdparty \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	$(FSO_CFLAGS) \
	-g -DDEBUG \
	$(NULL)

noinst_PROGRAMS = \
	$(TEST_PROGS) \
	$(NULL)

LDADD = \
	$(GLIB_LIBS) \
	$(GEE_LIBS) \
	$(FSO_LIBS) \
	$(top_builddir)/src/lib/libfsogsm.la

AM_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/src/lib \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fsoframework-2.0 \
	--pkg fsobasics-2.0 \
	--pkg fsotransport-2.0 \
	--pkg fsogsm-2.0 \
	--pkg fsotest-2.0 \
	--pkg fsogsm3rdparty \
	-g \
	$(NULL)

TEST_PROGS += testatcommand
testatcommand_SOURCES = testatcommand.vala

TEST_PROGS += testatparser
testatparser_SOURCES = testatparser.vala

TEST_PROGS += testcb
testcb_SOURCES = testcb.vala

TEST_PROGS += testconversions
testconversions_SOURCES = testconversions.vala

TEST_PROGS += testconst
testconst_SOURCES = testconst.vala

TEST_PROGS += testsms
testsms_SOURCES = testsms.vala smsdata.vala

TEST_PROGS += testsmsstorage
testsmsstorage_SOURCES = testsmsstorage.vala smsdata.vala

TEST_PROGS += testatresultiter
testatresultiter_SOURCES = testatresultiter.vala

# TEST_PROGS += testoptiongtm601
# FIXME adding the sources from the modem plugin itself to the list of sources for
# compilation of this test is ugly, we should rather load the plugin and use it the common
# way.
# testoptiongtm601_SOURCES = \
#	$(top_srcdir)/src/plugins/modem_option_gtm601/commands.vala \
#	testoptiongtm601.vala \
#	$(NULL)

CLEANFILES =
MAINTAINERCLEANFILES = \
	Makefile.in \
	$(NULL)
