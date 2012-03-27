include $(top_srcdir)/Makefile.decl

NULL=

confdir = $(sysconfdir)/freesmartphone/conf/htc_qualcomm_msm
dist_conf_DATA = \
	fsodeviced.conf \
	$(NULL)

# boards compatible with htc_qualcomm_msm
COMPAT = \
	raphael \
	diamond \
	$(NULL)

install-data-local:
	$(mkinstalldirs) $(DESTDIR)/$(sysconfdir)/freesmartphone/conf/
	for compat in $(COMPAT); do ln -sf ./htc_qualcomm_msm $(DESTDIR)/$(sysconfdir)/freesmartphone/conf/$$compat; done

MAINTAINERCLEANFILES = Makefile.in
