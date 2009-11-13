dbusconfdir = @DBUS_DIR@/system.d
dist_dbusconf_DATA = fsogsmd.conf

dbusservicedir = @DBUS_SERVICE_DIR@/../system-services
dbusservice_in_file = org.freesmartphone.ogsmd.service.in
dist_dbusservice_DATA = $(dbusservice_in_file:.service.in=.service)

isocodesdir = $(datadir)/fsogsmd
dist_isocodes_DATA = list-en1-semic-3.txt

CLEANFILES = $(dist_dbusservice_DATA)
MAINTAINERCLEANFILES = Makefile.in

