include $(top_srcdir)/Makefile.decl
NULL =

AM_CFLAGS = \
	-include $(CONFIG_HEADER) \
	-DG_LOG_DOMAIN=\"fsoaudio\" \
	$(NULL)
AM_VALAFLAGS =


sbin_PROGRAMS = fsoaudiod
fsoaudiod_SOURCES = main.vala
fsoaudiod_VALAFLAGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/vapi \
	--pkg config \
	--pkg posix \
	--pkg gio-2.0 \
	--pkg fsoframework-2.0 \
	--save-temps \
	$(DEBUG_VALAFLAGS) \
	$(NULL)
fsoaudiod_CFLAGS = \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(DEBUG_CFLAGS) \
	$(NULL)
fsoaudiod_LDADD = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)
