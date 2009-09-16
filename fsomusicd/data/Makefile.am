EXTRA_DIST = $(service_DATA)

servicedir = $(datadir)/dbus-1/services

service_in_files = org.freesmartphone.omusicd.service.in

service_DATA = $(service_in_files:.service.in=.service)

MAINTAINERCLEANFILE = Makefile.in $(service_DATA)

$(service_DATA): $(service_in_files)
	echo $(bindir) $< $@
	@sed -e "s|\@bindir\@|$(bindir)|" $<> $@
