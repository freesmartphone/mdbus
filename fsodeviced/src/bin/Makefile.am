include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-include $(CONFIG_HEADER) \
	-DG_LOG_DOMAIN=\"fsodeviced\" \
	$(NULL)
AM_VALAFLAGS =

sbin_PROGRAMS = fsodeviced

fsodeviced_SOURCES = main.vala
fsodeviced_VALAFLAGS = \
	--vapidir $(top_srcdir)/vapi \
	--pkg posix \
	--pkg gio-2.0 \
	--pkg fsoframework-2.0 \
	--save-temps \
	--basedir $(top_srcdir) \
	$(DEBUG_VALAFLAGS) \
	$(NULL)
fsodeviced_CFLAGS = \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(DEBUG_CFLAGS) \
	$(NULL)
fsodeviced_LDADD = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)

CLEANFILES =
MAINTAINERCLEANFILES = \
	Makefile.in \
	$(NULL)
