include $(top_srcdir)/Makefile.decl

NULL=

THISDIR=`basename $$PWD`

confdir = $(DESTDIR)/$(sysconfdir)/freesmartphone/conf/$(THISDIR)
dist_conf_DATA = \
	fsodeviced.conf \
	$(NULL)

# boards compatible with htc_qualcomm_msm
COMPAT = \
	trout \
	raphael \
	diamond \
	$(NULL)

install-data-local:
	$(mkinstalldirs) $(confdir)
	for compat in $(COMPAT); do ln -sf ./$(THISDIR) $(confdir)/../$$compat; done

MAINTAINERCLEANFILES = Makefile.in
