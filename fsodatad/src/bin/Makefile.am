include $(top_srcdir)/Makefile.decl
NULL =

AM_CPPFLAGS = \
	-include $(CONFIG_HEADER) \
	-DG_LOG_DOMAIN=\"fsodata\" \
	$(NULL)

sbin_PROGRAMS = fsodatad
fsodatad_SOURCES = main.vala
fsodatad_VALAFLAGS = \
	--vapidir $(top_srcdir)/vapi \
	--pkg posix \
	--pkg gio-2.0 \
	--pkg fsoframework-2.0 \
	--save-temps \
	--basedir $(top_srcdir) \
	$(NULL)
fsodatad_CPPFLAGS = \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(NULL)
fsodatad_LDADD = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)
