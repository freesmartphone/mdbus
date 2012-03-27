include $(top_srcdir)/Makefile.decl

NULL=

SUBDIRS = alsa-default

confdir = $(sysconfdir)/freesmartphone/conf/htc_qualcomm_dream
dist_conf_DATA = \
	fsodeviced.conf \
	alsa.conf \
	$(NULL)

# boards compatible with htc_qualcomm_dream
COMPAT = \
	trout \
	$(NULL)

install-data-local:
	$(mkinstalldirs) $(DESTDIR)/$(sysconfdir)/freesmartphone/conf/
	for compat in $(COMPAT); do ln -sf ./htc_qualcomm_dream $(DESTDIR)/$(sysconfdir)/freesmartphone/conf/$$compat; done

MAINTAINERCLEANFILES = Makefile.in
