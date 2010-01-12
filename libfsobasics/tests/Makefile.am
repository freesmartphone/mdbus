include $(top_srcdir)/Makefile.decl

NULL =

AM_CFLAGS = \
	-I$(top_srcdir) \
	-I$(top_srcdir)/fsobasics \
	$(GLIB_CFLAGS) \
	$(LIBNL_CFLAGS) \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(GLIB_LIBS) \
	$(LIBNL_LIBS) \
	../fsobasics/libfsobasics.la

VALAC_ARGS = \
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

EXTRA_DIST += \
	.testlogger.ini \
	testsmartkeyfile.ini \
	frameworkd.conf \
	textfile.txt \
	$(NULL)

#
# async test
#
TEST_PROGS += testasync
testasync_VALASOURCES = testasync.vala
testasync_SOURCES = testasync.c
$(testasync_SOURCES): $(testasync_VALASOURCES)
	$(VALAC) $(VALAC_ARGS) $^
	touch $@
testasync_LDADD = $(progs_ldadd)
EXTRA_DIST += $(testasync_VALASOURCES)

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
# inotifier test
#
TEST_PROGS += testinotifier
testinotifier_VALASOURCES = testinotifier.vala
testinotifier_SOURCES = testinotifier.c
$(testinotifier_SOURCES): $(testinotifier_VALASOURCES)
	$(VALAC) $(VALAC_ARGS) $^
	touch $@
testinotifier_LDADD = $(progs_ldadd)
EXTRA_DIST += $(testinotifier_VALASOURCES)

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

#
# netlinknotifier test
#
TEST_PROGS += testnetlinknotifier
testnetlinknotifier_VALASOURCES = testnetlinknotifier.vala
testnetlinknotifier_SOURCES = testnetlinknotifier.c
$(testnetlinknotifier_SOURCES): $(testnetlinknotifier_VALASOURCES)
	$(VALAC) $(VALAC_ARGS) $^
	touch $@
testnetlinknotifier_LDADD = $(progs_ldadd)
EXTRA_DIST += $(testnetlinknotifier_VALASOURCES)

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
# process test
#
TEST_PROGS += testprocess
testprocess_VALASOURCES = testprocess.vala
testprocess_SOURCES = testprocess.c
$(testprocess_SOURCES): $(testprocess_VALASOURCES)
	$(VALAC) $(VALAC_ARGS) $^
	touch $@
testprocess_LDADD = $(progs_ldadd)
EXTRA_DIST += $(testprocess_VALASOURCES)

#
# overlay test
#
TEST_PROGS += testoverlay
testoverlay_VALASOURCES = testoverlay.vala
testoverlay_SOURCES = testoverlay.c
$(testoverlay_SOURCES): $(testoverlay_VALASOURCES)
	$(VALAC) $(VALAC_ARGS) $^
	touch $@
testoverlay_LDADD = $(progs_ldadd)
EXTRA_DIST += $(testoverlay_VALASOURCES)

#
# threading test
#
TEST_PROGS += testthreading
testthreading_VALASOURCES = testthreading.vala
testthreading_SOURCES = testthreading.c
$(testthreading_SOURCES): $(testthreading_VALASOURCES)
	$(VALAC) $(VALAC_ARGS) $^
	touch $@
testthreading_LDADD = $(progs_ldadd)
EXTRA_DIST += $(testthreading_VALASOURCES)

#
#
#
CLEANFILES = \
    $(TEST_PROGS) \
    *.? \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  *.la \
  *.lo \
  $(NULL)
