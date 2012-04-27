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
	--pkg fsogsm3rdparty

TEST_PROGS += testatcommand
testatcommand_SOURCES = testatcommand.vala
testatcommand_LDADD = $(progs_ldadd)

TEST_PROGS += testatparser
testatparser_SOURCES = testatparser.vala
testatparser_LDADD = $(progs_ldadd)

TEST_PROGS += testcb
testcb_SOURCES = testcb.vala
testcb_LDADD = $(progs_ldadd)

TEST_PROGS += testconversions
testconversions_SOURCES = testconversions.vala
testconversions_LDADD = $(progs_ldadd)

TEST_PROGS += testconst
testconst_SOURCES = testconst.vala
testconst_LDADD = $(progs_ldadd)

TEST_PROGS += testsms
testsms_SOURCES = testsms.vala smsdata.vala
testsms_LDADD = $(progs_ldadd)

TEST_PROGS += testsmsstorage
testsmsstorage_SOURCES = testsmsstorage.vala smsdata.vala
testsmsstorage_LDADD = $(progs_ldadd)

# TEST_PROGS += testoptiongtm601
# FIXME adding the sources from the modem plugin itself to the list of sources for
# compilation of this test is ugly, we should rather load the plugin and use it the common
# way.
# testoptiongtm601_SOURCES = \
#	$(top_srcdir)/src/plugins/modem_option_gtm601/commands.vala \
#	testoptiongtm601.vala \
#	$(NULL)
#testoptiongtm601_LDADD = \
#	$(progs_ldadd) \
#	$(NULL)

MAINTAINERCLEANFILES = \
	$(addsuffix .c,$(noinst_PROGRAMS)) \
	testatcommand_vala.stamp \
	testatparser_vala.stamp \
	testcb_vala.stamp \
	testconversions_vala.stamp \
	testconst_vala.stamp \
	testsms_vala.stamp \
	testsmsstorage_vala.stamp \
	$(NULL)

EXTRA_DIST += \
	$(MAINTAINERCLEANFILES) \
	$(NULL)
