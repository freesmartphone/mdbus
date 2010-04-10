include $(top_srcdir)/Makefile.decl

NULL =

VALAC_ARGS = \
	-C  --vapidir vapi \
        --pkg fsodevice-2.0 \
        --pkg fsoframework-2.0 \
        --save-temps \
        --basedir $(top_srcdir)

AM_CFLAGS = \
	$(DEPS_CFLAGS) \
	$(NULL)

BUILT_SOURCES = .vala.stamp

bin_PROGRAMS = fso-alsa

fso_alsa_VALASOURCES = \
	main.vala \
	$(NULL)

fso_alsa_SOURCES = \
	$(fso_alsa_VALASOURCES:.vala=.c) \
	$(NULL)

$(BUILT_SOURCES): $(fso_alsa_VALASOURCES)
	$(VALAC) $(VALAC_ARGS) $^
	touch $@

fso_alsa_LDADD = \
	$(DEPS_LIBS) \
	-lfsodevice \
	$(NULL)

EXTRA_DIST += \
	$(fso_alsa_VALASOURCES) \
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
