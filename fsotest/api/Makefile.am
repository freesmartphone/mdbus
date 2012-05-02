include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	$(GLIB_CFLAGS) \
	$(FSO_CFLAGS) \
	-include $(CONFIG_HEADER) \
	$(NULL)
AM_VALAFLAGS = \
	--vapidir $(top_srcdir)/vapi \
	--pkg gio-2.0 \
	--pkg gee-1.0 \
	--pkg fsotest-2.0 \
	--pkg fsobasics-2.0 \
	--pkg fsoframework-2.0 \
	--pkg fsoresource-2.0 \
	--pkg fso-glib-1.0 \
	--save-temps \
	--basedir $(top_srcdir) \
	$(NULL)
LDADD = \
	$(GLIB_LIBS) \
	$(FSO_LIBS) \
	$(NULL)

if WANT_DEBUG
AM_VALAFLAGS += -g -D DEBUG
AM_CFLAGS += -ggdb -O0
endif

bin_PROGRAMS = \
	testusage \
	testgsm \
	$(NULL)

testusage_SOURCES = testusage.vala
testgsm_SOURCES = testgsm.vala

CLEANFILES =
MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
