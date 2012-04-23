include $(top_srcdir)/Makefile.decl
NULL =

dbusconfdir = @DBUS_DIR@/system.d
dist_dbusconf_DATA = fsotdld.conf

dbusservicedir = @DBUS_SERVICE_DIR@/../system-services
dbusservice_in_file = org.freesmartphone.otdld.service.in
dist_dbusservice_DATA = $(dbusservice_in_file:.service.in=.service)

EXTRA_DIST += fsotdld.service

CLEANFILES = $(dist_dbusservice_DATA)
MAINTAINERCLEANFILES = Makefile.in
