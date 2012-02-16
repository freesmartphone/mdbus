include $(top_srcdir)/Makefile.decl

NULL =

AM_CFLAGS = \
	$(FSOFRAMEWORK_CFLAGS) \
	-include $(CONFIG_HEADER) \
	$(NULL)

VALAC_ARGS = \
	--vapidir ../vapi \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fsotest-2.0 \
	--pkg fsobasics-2.0 \
	--pkg fsoframework-2.0 \
	--pkg fsoresource-2.0 \
	--pkg fso-glib-1.0 \
	--save-temps \
	--basedir $(top_srcdir)

if WANT_DEBUG
VALAC_ARGS += -g -D DEBUG
AM_CFLAGS += -ggdb -O0
endif

progs_ldadd = \
	$(FSOFRAMEWORK_LIBS) \
	$(NULL)

noinst_PROGRAMS = $(TEST_PROGS)

TEST_PROGS += testusage
testusage_VALASOURCES = testusage.vala
testusage_SOURCES = testusage.c
$(testusage_SOURCES): $(testusage_VALASOURCES)
	$(VALAC) $(VALAC_ARGS) $^
	touch $@
testusage_LDADD = $(progs_ldadd)
EXTRA_DIST += $(testusage_VALASOURCES)

CLEANFILES = \
    $(TEST_PROGS) \
    *.? \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  *.la \
  *.lo \
  $(NULL)
