include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	$(GLIB_CFLAGS) \
	$(ALSA_CFLAGS) \
	$(NULL)

INCLUDES = \
	-I../fsoframework

noinst_PROGRAMS = $(TEST_PROGS)

VALAC_ARGS = \
	-C \
	--basedir $(top_srcdir) \
	--vapidir ../vapi/ \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg gio-2.0

#
# alsa test
#
TEST_PROGS += testalsa
testalsa_VALASOURCES = testalsa.vala
testalsa_SOURCES = testalsa.c
$(testalsa_SOURCES): $(testalsa_VALASOURCES)
	$(VALAC) $(VALAC_ARGS) $^
	touch $@
testalsa_LDADD = $(GLIB_LIBS) $(ALSA_LIBS)
EXTRA_DIST += $(testalsa_VALASOURCES)




CLEANFILES = \
    $(TEST_PROGS) \
    *.? \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  *.la \
  *.lo \
  $(NULL)
