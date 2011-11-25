include $(top_srcdir)/Makefile.decl

NULL =

VALAC_ARGS = \
	-C --vapidir vapi \
		--pkg posix \
		--pkg gio-2.0 \
		--save-temps \
		--basedir $(top_srcdir)
		$(NULL)

INCLUDES = \
	$(GLIB_CFLAGS) \
	-include $(CONFIG_HEADER) \
	$(NULL)

BUILT_SOURCES = .vala.stamp

bin_PROGRAMS = fso-raw

fso_raw_VALASOURCES = \
	main.vala \
	$(NULL)

fso_raw_SOURCES = \
	$(fso_raw_VALASOURCES:.vala=.c) \
	$(NULL)

$(BUILT_SOURCES): $(fso_raw_VALASOURCES)
	$(VALAC) $(VALAC_ARGS) $^
	touch $@

fso_raw_LDADD = \
	$(GLIB_LIBS) \
	$(NULL)

EXTRA_DIST += \
	$(fso_raw_VALASOURCES) \
	$(BUILT_SOURCES) \
	$(NULL)

CLEANFILES = \
	*.c \
	*.h \
	$(BUILT_SOURCES) \
	$(NULL)

MAINTAINERCLEANFILES = \
	Makefile.in \
	$(NULL)
