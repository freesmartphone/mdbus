NULL = 

AUTOMAKE_OPTIONS = subdir-objects


MUSIC_DIR ?= "g_get_user_special_dir(G_USER_DIRECTORY_MUSIC)"
CONFIG_DIR ?= "g_build_filename(g_get_user_config_dir(),\"fsomusicd\")"
CONFIG_PATH ?= "g_build_filename(g_get_user_config_dir(),\"fsomusicd\",\"main.conf\")"  #$(CONFIG_DIR)"\"/main.conf\""
PLAYLIST_DIR ?= "g_build_filename(g_get_user_config_dir(),\"fsomusicd\",\"playlists\")" #"\"/playlists\""

INCLUDES = \
	-D_GNU_SOURCE \
	$(DEPS_CFLAGS) \
	-include $(CONFIG_HEADER) \
	$(NULL)

BUILT_SOURCES = .vala.stamp

sbin_PROGRAMS = fsomusicd

fsomusicd_VALASOURCES = \
	playlist.vala \
	musicplayer.vala \
	main.vala \
	interfaces.vala \
	config.vala \
	$(NULL)

fsomusicd_SOURCES = \
	$(fsomusicd_VALASOURCES:.vala=.c) \
	$(fsomusicd_VALASOURCES:.vala=.h) \
	$(NULL)

.vala.stamp: $(fsomusicd_VALASOURCES)
	$(VALAC) -C --pkg  dbus-glib-1 \
	    --pkg gstreamer-0.10 \
	    --pkg posix \
	    --pkg fsobasics-2.0 \
	    --pkg fsoframework-2.0 \
	    --pkg fso-glib-1.0 \
		--pkg gee-1.0 \
	    --vapidir=. \
	    --save-temps  $^
	touch $@
fsomusicd_LDADD = \
		    $(DEPS_LIBS) \
		    $(NULL)

EXTRA_DIST = \
	$(fsomusicd_VALASOURCES) \
	src/.vala.stamp \
	$(NULL)

MAINTAINERCLEANFILE = Makefile.in
