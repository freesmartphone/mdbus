include $(top_srcdir)/Makefile.decl

NULL=

THISDIR=`basename $$PWD`

confdir = @DBUS_DIR@/../freesmartphone/conf/$(THISDIR)
dist_conf_DATA = \
	fsodeviced.conf \
	$(NULL)

# boards compatible with openmoko_gta
COMPAT = \
	GTA01 \
	GTA02 \
	$(NULL)
	
install-data-local: install-dist_confDATA
	for compat in $(COMPAT); do ln -sf ./$(THISDIR) $(confdir)/../$$compat; done

MAINTAINERCLEANFILES = Makefile.in
