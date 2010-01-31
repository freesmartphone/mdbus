include $(top_srcdir)/Makefile.decl

NULL=

THISDIR=`basename $$PWD`

confdir = $(DESTDIR)/$(sysconfdir)/freesmartphone/conf/$(THISDIR)
dist_conf_DATA = \
	fsodeviced.conf \
	$(NULL)

# boards compatible with openmoko_gta
COMPAT = \
	GTA01 \
	GTA02 \
	$(NULL)

install-data-local:
	$(mkinstalldirs) $(confdir)
	for compat in $(COMPAT); do ln -sf ./$(THISDIR) $(confdir)/../$$compat; done

MAINTAINERCLEANFILES = Makefile.in
