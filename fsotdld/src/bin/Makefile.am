include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-include $(CONFIG_HEADER) \
	-DG_LOG_DOMAIN=\"fsotdld\" \
	$(NULL)
AM_VALAFLAGS =

sbin_PROGRAMS = fsotdld
fsotdld_SOURCES = main.vala
fsotdld_VALAFLAGS = \
	--vapidir $(top_srcdir)/vapi \
	--pkg posix \
	--pkg gio-2.0 \
	--pkg fsoframework-2.0 \
	--save-temps \
	--basedir $(top_srcdir) \
	$(DEBUG_VALAFLAGS) \
	$(NULL)
fsotdld_CFLAGS = \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(DEBUG_CFLAGS) \
	$(NULL)
fsotdld_LDADD = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)

CLEANFILES =
MAINTAINERCLEANFILES = \
	Makefile.in \
	$(NULL)
