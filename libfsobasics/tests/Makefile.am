include $(top_srcdir)/Makefile.decl

NULL =

AM_CFLAGS = \
	-I$(top_srcdir) \
	-I$(top_srcdir)/fsobasics \
	$(GLIB_CFLAGS) \
	$(LIBNL_CFLAGS) \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

LDADD = \
	$(GLIB_LIBS) \
	$(LIBNL_LIBS) \
	$(top_builddir)/fsobasics/libfsobasics.la \
	$(NULL)

AM_VALAFLAGS = \
	-C \
	--thread \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/fsobasics \
	--vapidir $(top_srcdir)/vapi \
	--pkg posix \
	--pkg linux \
	--pkg libnl-2.0 \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg fsobasics-2.0
	$(NULL)

EXTRA_DIST += \
	.testlogger.ini \
	testsmartkeyfile.ini \
	frameworkd.conf \
	textfile.txt \
	$(NULL)

TEST_PROGS += \
	testasync \
	testasyncworker \
	testinotifier \
	testnetlinknotifier \
	testsmartkeyfile \
	testlogger \
	testutilities \
	testnetlink \
	testoverlay \
	testthreading \
	testbinreader \
	testbinbuilder \
	$(NULL)

#	testkobjectnotifier

noinst_PROGRAMS = $(TEST_PROGS)

testasync_SOURCES = testasync.vala

testasyncworker_SOURCES = testasyncworker.vala

testinotifier_SOURCES = testinotifier.vala

# testkobjectnotifier_SOURCES = testkobjectnotifier.vala

testnetlinknotifier_SOURCES = testnetlinknotifier.vala

testsmartkeyfile_SOURCES = testsmartkeyfile.vala

testlogger_SOURCES = testlogger.vala

testutilities_SOURCES = testutilities.vala

testnetlink_SOURCES = testnetlink.vala

testoverlay_SOURCES = testoverlay.vala

testthreading_SOURCES = testthreading.vala

testbinbuilder_SOURCES = testbinbuilder.vala

testbinreader_SOURCES = testbinreader.vala

CLEANFILES = \
    $(TEST_PROGS) \
    $(NULL)

MAINTAINERCLEANFILES = \
	$(addsuffix .c,$(noinst_PROGRAMS)) \
	testasync_vala.stamp \
	testasyncworker_vala.stamp \
	testinotifier_vala.stamp \
	testnetlinknotifier_vala.stamp \
	testsmartkeyfile_vala.stamp \
	testlogger_vala.stamp \
	testutilities_vala.stamp \
	testnetlink_vala.stamp \
	testoverlay_vala.stamp \
	testthreading_vala.stamp \
	testbinreader_vala.stamp \
	testbinbuilder_vala.stamp \
	$(NULL)

EXTRA_DIST += \
	$(MAINTAINERCLEANFILES) \
	$(NULL)
