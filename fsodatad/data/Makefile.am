include $(top_srcdir)/Makefile.decl
NULL =

dbusconfdir = @DBUS_DIR@/system.d
dist_dbusconf_DATA = fsodatad.conf

dbusservicedir = @DBUS_SERVICE_DIR@/../system-services
dbusservice_in_file = org.freesmartphone.odatad.service.in
dist_dbusservice_DATA = $(dbusservice_in_file:.service.in=.service)

worldcodesdir = $(datadir)/fsodatad
dist_worldcodes_DATA = iso3361+dialcode.txt zone.tab

CLEANFILES = $(dist_dbusservice_DATA)
MAINTAINERCLEANFILES = Makefile.in
