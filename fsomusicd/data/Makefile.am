EXTRA_DIST = $(service_DATA)

dbusconfdir = @DBUS_DIR@/system.d
dist_dbusconf_DATA = fsomusicd.conf

servicedir = @DBUS_SERVICE_DIR@/../system-services

service_in_files = org.freesmartphone.omusicd.service.in

service_DATA = $(service_in_files:.service.in=.service)

MAINTAINERCLEANFILE = Makefile.in $(service_DATA)

$(service_DATA): $(service_in_files)
	echo $(bindir) $< $@
	@sed -e "s|\@bindir\@|$(bindir)|" $<> $@
