include $(top_srcdir)/Makefile.decl

NULL =

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir ../vapi \
	--pkg gee-1.0 \
	--pkg posix \
	--pkg linux \
	--pkg dbus-glib-1 \
	--pkg fsobasics-2.0 \
	--pkg util \
	--save-temps

if WANT_DEBUG
VALAC_ARGS += -D DEBUG
endif

INCLUDES = \
	$(DBUS_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	-include $(CONFIG_HEADER) \
	$(NULL)

BUILT_SOURCES = .vala.stamp

sbin_PROGRAMS = fsoinitd

fsoinitd_VALASOURCES = \
	main.vala \
	contracts.vala \
	actionqueue.vala \
	initprocessworker.vala \
	configurations/baseconfiguration.vala \
	spawnprocessaction.vala \
	sysfsconfigaction.vala \
	mountfilesystemaction.vala \
	configurenetworkinterfaceaction.vala \
	additionalbootprocessaction.vala \
	setuphostnameaction.vala \
	dbusactivatoraction.vala \
	$(NULL)

if WANT_MACHINE_PALMPRE
fsoinitd_VALASOURCES += configurations/palmpre.vala
endif

if WANT_MACHINE_OPENMOKO_GTA02
fsoinitd_VALASOURCES += configurations/om-gta02.vala
endif

if WANT_MACHINE_DUMMY
fsoinitd_VALASOURCES += configurations/dummy.vala
endif

fsoinitd_SOURCES = \
	$(fsoinitd_VALASOURCES:.vala=.c) \
	$(NULL)

$(BUILT_SOURCES): $(fsoinitd_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@

fsoinitd_LDADD = \
	$(DBUS_LIBS) \
	$(GLIB_LIBS) \
	$(GEE_LIBS) \
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
