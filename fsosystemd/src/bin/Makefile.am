include $(top_srcdir)/Makefile.decl

NULL =

AM_CFLAGS = \
	-include $(CONFIG_HEADER) \
	-DG_LOG_DOMAIN=\"fsosystemd\" \
	$(NULL)

AM_VALAFLAGS = \
	$(NULL)


sbin_PROGRAMS = fsosystemd

fsosystemd_SOURCES = main.vala
fsosystemd_VALAFLAGS = \
	--vapidir $(top_srcdir)/vapi \
	--pkg posix \
	--pkg gio-2.0 \
	--pkg fsoframework-2.0 \
	--basedir $(top_srcdir) \
	$(DEBUG_VALAFLAGS) \
	$(NULL)
fsosystemd_CFLAGS = \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(DEBUG_CFLAGS) \
	$(NULL)
fsosystemd_LDADD = \
	$(FSO_LIBS) \
	$(GLIB_LIBS) \
	$(NULL)
