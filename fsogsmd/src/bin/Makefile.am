include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-include $(CONFIG_HEADER) \
	-DG_LOG_DOMAIN=\"fsogsm\" \
	$(NULL)
AM_VALAFLAGS =

sbin_PROGRAMS = fsogsmd
fsogsmd_SOURCES = main.vala
fsogsmd_VALAFLAGS = \
	--vapidir $(top_srcdir)/vapi \
	--pkg posix \
	--pkg gio-2.0 \
	--pkg fsoframework-2.0 \
	--save-temps \
	--basedir $(top_srcdir) \
	$(DEBUG_VALAFLAGS) \
	$(NULL)
fsogsmd_CFLAGS = \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(DEBUG_CFLAGS) \
	$(NULL)
fsogsmd_LDADD = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)

CLEANFILES =
MAINTAINERCLEANFILES = \
	Makefile.in \
	$(NULL)
