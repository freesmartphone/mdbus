include $(top_srcdir)/Makefile.decl

NULL=

confdir = $(sysconfdir)/freesmartphone/conf/motorola_ezx
dist_conf_DATA = \
	fsodeviced.conf \
	$(NULL)

# boards compatible with motorola_ezx
COMPAT = \
	MotorolaEZXA780 \
	MotorolaEZXA1200 \
	MotorolaEZXE2 \
	MotorolaEZXE6 \
	$(NULL)

install-data-local:
	$(mkinstalldirs) $(DESTDIR)/$(sysconfdir)/freesmartphone/conf/
	for compat in $(COMPAT); do ln -sf ./motorola_ezx $(DESTDIR)/$(sysconfdir)/freesmartphone/conf/$$compat; done

MAINTAINERCLEANFILES = Makefile.in
