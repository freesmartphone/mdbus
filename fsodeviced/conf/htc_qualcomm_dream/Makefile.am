include $(top_srcdir)/Makefile.decl

NULL=

THISDIR = `basename $$PWD`

confdir = $(sysconfdir)/freesmartphone/conf/$(THISDIR)
dist_conf_DATA = \
	fsodeviced.conf \
	$(NULL)

# boards compatible with htc_qualcomm_dream
COMPAT = \
	trout \
	$(NULL)

install-data-local:
	$(mkinstalldirs) $(DESTDIR)/etc/freesmartphone/conf/
	for compat in $(COMPAT); do ln -sf ./$(THISDIR) $(DESTDIR)/etc/freesmartphone/conf/$$compat; done

MAINTAINERCLEANFILES = Makefile.in
