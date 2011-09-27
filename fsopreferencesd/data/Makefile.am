include $(top_srcdir)/Makefile.decl

dbusconfdir = @DBUS_DIR@/system.d
dist_dbusconf_DATA = fsopreferencesd.conf

dbusservicedir = @DBUS_SERVICE_DIR@/../system-services
dbusservice_in_file = org.freesmartphone.opreferencesd.service.in
dist_dbusservice_DATA = $(dbusservice_in_file:.service.in=.service)

SUBDIRS = schemas

CLEANFILES = $(dist_dbusservice_DATA)
MAINTAINERCLEANFILES = Makefile.in

