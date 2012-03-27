include $(top_srcdir)/Makefile.decl

NULL=

confdir = $(sysconfdir)/freesmartphone/conf/nexusone
dist_conf_DATA = \
	fsodeviced.conf \
	$(NULL)

# boards compatible with htc_qualcomm_dream
COMPAT = \
	mahimahi \
	$(NULL)

install-data-local:
	$(mkinstalldirs) $(DESTDIR)/$(sysconfdir)/freesmartphone/conf/
	for compat in $(COMPAT); do ln -sf ./nexusone $(DESTDIR)/$(sysconfdir)/freesmartphone/conf/$$compat; done

MAINTAINERCLEANFILES = Makefile.in
