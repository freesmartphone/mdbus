NULL = 

AUTOMAKE_OPTIONS = subdir-objects



BUILT_SOURCES = .vala.stamp

sbin_PROGRAMS = fsomusicd

fsomusicd_VALASOURCES = \
	$(NULL)

fsomusicd_SOURCES = \
	$(fsomusicd_VALASOURCES:.vala=.c) \
	$(fsomusicd_VALASOURCES:.vala=.h) \
	$(NULL)

src/.vala.stamp: $(fsomuscd_VALASOURCES)
	$(VALAC) -c --pkg  dbus-glib-1 gstreamer-0.10 --save-temps  $^
	touch $@


EXTRA_DIST = \
	$(fsommusicd_VALASOURCES) \
	src/.vala.stamp \
	$(NULL)

