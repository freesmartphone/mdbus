include $(top_srcdir)/Makefile.decl

NULL =

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir ../vapi \
	--pkg util \
	--pkg gee-1.0 \
	--pkg posix \
	--pkg linux \
	--pkg fsosystem-2.0 \
	--pkg fsobasics-2.0 \
	--save-temps

if WANT_DEBUG
VALAC_ARGS += -D DEBUG
endif

INCLUDES = \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	$(FSO_CFLAGS) \
	-include $(CONFIG_HEADER) \
	$(NULL)

BUILT_SOURCES = .vala.stamp

sbin_PROGRAMS = fsoinitd

fsoinitd_VALASOURCES = \
	util.vala \
	main.vala \
	$(NULL)

fsoinitd_SOURCES = \
	$(fsoinitd_VALASOURCES:.vala=.c) \
	$(NULL)

$(BUILT_SOURCES): $(fsoinitd_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@

# static build
#fsoinitd_LDFLAGS = \
#	-static \
#	-all-static \
#	$(NULL)

fsoinitd_LDADD = \
	$(GLIB_LIBS) \
	$(GEE_LIBS) \
	$(FSO_LIBS) \
	$(NULL)

EXTRA_DIST += \
	$(fsoinitd_VALASOURCES) \
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
